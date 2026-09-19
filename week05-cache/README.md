# week05 · 캐시 서버 (Redis 인메모리 캐시와 웹 캐시)

실습 가이드: `실습_W5_캐시.html`

## 1. 목표

- **Redis** 를 설치·기동·보안 설정하고 `redis-cli` 로 String / Hash / TTL 명령을 다룬다.
- **Cache-Aside** 패턴으로 애플리케이션 캐시를 구현해, 2초가 걸리는 백엔드 응답을 가속한다.
- **Nginx 리버스 프록시 캐시** 와 **Squid 포워드 프록시 캐시** 로 HTTP 응답 자체를 캐싱한다.
- Nginx(HTTP 응답 캐시)와 Redis(데이터 캐시)를 **이중으로 결합** 하고, 응답 시간으로 캐시 효과를 정량 측정한다.

캐시가 놓이는 자리는 이론 5주차 24p의 정리와 같다.

```
[클라이언트]
    |
    +--> Nginx 리버스 프록시 캐시 (:80)     ---+   [캐시 서버 VM]
    |                                          |
    +--> Squid 포워드 프록시 캐시 (:3128)   ---+
                                               |
                                               v
                              Flask 앱 (:5000) <--> Redis (:6379)   [백엔드 서버 VM]
                                               |    (캐시 어사이드)
                                               v
                              데이터 소스 (느린 조회, 약 2초)
```

## 2. 사전 조건

| VM | 자리표시자 | IP 할당 | 설치할 것 |
|---|---|---|---|
| `webserver-{{STUDENT_ID}}` (백엔드) | `{{WEBSERVER_IP}}` | Shared Network DHCP(`10.0.X.X`) | Flask 앱, Redis |
| `cache-{{STUDENT_ID}}` (캐시) | `{{CACHE_IP}}` | Shared Network DHCP(`10.0.X.X`) | Nginx, Squid |

- 두 VM이 같은 **기본 Shared Network**에 있고 사설 IP(`10.0.X.X`)로 통신되어야 한다. IP는 고정하지 않고 `terraform output` 또는 콘솔에서 확인한 값을 쓴다.
- 두 VM 모두 SSH 접속이 되고, Egress(아웃바운드)가 허용되어 있어야 한다.
- 실습 트래픽 포트: 백엔드 `5000`과 Squid `3128`은 외부에 열지 않는다. Nginx `80`을 포함해 세 포트 모두 VPN 연결 상태에서 사설 IP로 직접 접근한다(Shared Network는 포트포워딩이 없는 네트워크 오퍼링이라 만들 수도 없다).
- VPN 연결 유지.

## 3. 파일

| 파일 | 설명 |
|---|---|
| `app.py` | Flask 백엔드 앱 최종 형태. 엔드포인트 3개(`/api/products`, `/api/products-cached`, `/api/products-dual`) |
| `requirements.txt` | pip 로 설치할 때 쓰는 의존성 목록. 가이드는 apt 설치를 권장한다 |
| `nginx-cache.conf` | `/etc/nginx/sites-available/backend-proxy` 최종 형태. 캐시 존 정의는 `nginx.conf` 의 `http` 블록에 넣는다(파일 상단 주석 참고) |
| `squid.conf.snippet` | `/etc/squid/squid.conf` 에 추가하는 `cache_dir` 한 줄과 적용 순서 |
| `bench.sh` | Part 7 응답 시간 비교를 반복 측정하고 평균을 출력 |

## 4. 실행 순서

### 4-1. 백엔드 서버 VM

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs/week05-cache
chmod +x bench.sh
```

Flask 와 Redis 클라이언트, Redis 서버를 설치한다.

```bash
sudo apt install -y python3-pip python3-flask python3-redis redis-server
```

앱을 배치한다.

```bash
mkdir -p /home/ubuntu/backend-app
cp app.py /home/ubuntu/backend-app/app.py
```

Redis 보안 설정(`/etc/redis/redis.conf`).

```conf
# 로컬(백엔드 서버 VM)에서만 접근 허용
bind 127.0.0.1 ::1

# 비밀번호 인증 (강한 값으로 교체한다. 이 파일은 커밋하지 않는다)
requirepass {{REDIS_PASSWORD}}
```

```bash
sudo systemctl restart redis-server
redis-cli -a '{{REDIS_PASSWORD}}' PING      # PONG
```

`requirepass` 를 설정했다면 앱에도 같은 값을 넘긴다. `app.py` 는 `REDIS_PASSWORD` 환경 변수를 읽는다.

systemd 서비스로 등록한다(`/etc/systemd/system/backend-app.service`).

```ini
[Unit]
Description=Flask Backend Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/backend-app
ExecStart=/usr/bin/python3 /home/ubuntu/backend-app/app.py
Restart=always
# requirepass 를 설정한 경우에만 추가한다
# Environment=REDIS_PASSWORD={{REDIS_PASSWORD}}

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backend-app
sudo systemctl status backend-app
```

### 4-2. 캐시 서버 VM

```bash
sudo apt update && sudo apt install -y git nginx squid
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs/week05-cache
chmod +x bench.sh
```

캐시 존을 `/etc/nginx/nginx.conf` 의 `http` 블록 안에 추가한다.

```nginx
http {
    ...
    proxy_cache_path /var/cache/nginx/api_cache
                     levels=1:2
                     keys_zone=api_cache:10m
                     max_size=100m
                     inactive=60m;
    ...
}
```

```bash
sudo mkdir -p /var/cache/nginx/api_cache
```

프록시 설정을 배치하고 활성화한다.

```bash
sed 's/{{WEBSERVER_IP}}/<webserver 실제 사설 IP>/g' nginx-cache.conf \
  | sudo tee /etc/nginx/sites-available/backend-proxy

sudo ln -s /etc/nginx/sites-available/backend-proxy /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

Squid 설정을 추가하고 캐시 디렉터리를 초기화한다.

```bash
cat squid.conf.snippet | sudo tee -a /etc/squid/squid.conf

sudo systemctl stop squid
sudo rm -rf /var/spool/squid/*
sudo squid -z
sleep 3
sudo systemctl start squid
sudo systemctl status squid
```

> `sudo rm -rf /var/spool/squid/*` 는 캐시를 전부 지운다. 실습 환경 전용 명령이며, 경로를 반드시 확인한 뒤 실행한다.

## 5. 검증 방법

### 5-1. 스크립트로 한 번에

두 VM 에서 각각 실행한 뒤 결과를 합쳐 표로 정리한다.

```bash
WEBSERVER_IP=<webserver 실제 사설 IP> CACHE_IP=<cache 실제 사설 IP> ./bench.sh 3
```

### 5-2. 항목별 통과 기준

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| 백엔드 기동 | `systemctl status backend-app` | `active (running)` |
| 원본 응답 | `time curl localhost:5000/api/products` | `real` 약 2초 |
| Redis 기본 | `redis-cli` 에서 `SET` / `GET` / `SETEX` / `TTL` | `OK`, 값, 남은 초 |
| Cache-Aside | `/api/products-cached` 2회 호출 | 1회 `"source":"database"`, 2회 `"source":"redis"` |
| Redis 키 확인 | `redis-cli TTL products:all` | 0 이상의 정수 (`-2` 면 키 없음) |
| Nginx 캐시 | `curl -I localhost/api/products` 2회 | 2회째 `X-Cache-Status: HIT` |
| 캐시 파일 | `sudo ls -lR /var/cache/nginx/api_cache/` | `levels=1:2` 구조로 파일 생성 |
| 조건부 우회 | `curl -I "localhost/api/products?nocache=1"` | 항상 `MISS` |
| stale 캐시 | 백엔드 중지 후 `curl -I localhost/api/products` | `X-Cache-Status: STALE`, 200 유지 |
| Squid 캐시 | `sudo cat /var/log/squid/access.log` | 1회 `TCP_MISS/200`, 2회 `TCP_MEM_HIT/200` |
| 이중 캐싱 | `/api/products-dual` 을 0 / 5 / 15 / 35초 시점 호출 | HIT → HIT → MISS+`redis_cached:true` → MISS+`redis_cached:false` |

이중 캐싱 시점별 기대 동작 (Nginx 10초, Redis 30초, DB 조회 2초):

| 시점 | Nginx | Redis | 동작 / 응답 시간 |
|---|---|---|---|
| 0초 | MISS | MISS | DB 조회 → Redis 저장 → Nginx 저장 (약 2초) |
| 1~9초 | HIT | 조회 없음 | Nginx 에서 즉시 응답 (약 0.01초) |
| 10~29초 | MISS | HIT | Redis 에서 Flask 응답 (약 0.02초) |
| 30초 이후 | MISS | MISS | 모든 캐시 만료 → DB 재조회 (약 2초) |

## 6. 정리 (rollback)

### 캐시 서버 VM

```bash
# Nginx 캐시 비활성화
sudo unlink /etc/nginx/sites-enabled/backend-proxy
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# 캐시 파일 삭제
sudo rm -rf /var/cache/nginx/api_cache/*

# nginx.conf 에 추가한 proxy_cache_path 블록을 제거하고 다시 검사
sudo vim /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl reload nginx

# Squid 중지 (설정 파일에 추가한 cache_dir 줄도 되돌린다)
sudo systemctl disable --now squid
sudo vim /etc/squid/squid.conf
```

### 백엔드 서버 VM

```bash
# 앱 중지
sudo systemctl disable --now backend-app
sudo rm -f /etc/systemd/system/backend-app.service
sudo systemctl daemon-reload

# 실습 키만 삭제한다. FLUSHALL 은 쓰지 않는다.
redis-cli -a '{{REDIS_PASSWORD}}' DEL products:all

# Redis 중지
sudo systemctl disable --now redis-server
```

`requirepass` 로 쓴 비밀번호는 실습이 끝나면 폐기한다. 저장소·과제 캡처에 그대로 남기지 않는다.

이번 주 확인이 끝났으면 VM(webserver·cache)을 정리(Destroy)한다. 기본 Shared Network는 이 실습이 만든 것이 아니므로 삭제되지 않는다. 6주차는 이 환경을 이어 쓰지 않고 새로 만든다.
