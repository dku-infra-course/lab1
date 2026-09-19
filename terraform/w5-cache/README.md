# W5 실습 환경 (Terraform) - 캐시 서버 (Redis, Nginx, Squid)

5주차 실습 가이드 `실습_W5_캐시.html` 검증용 환경이다.
**기존 공용 Shared Network 에 2대를 올린다.** VPN 을 켜면 사설 IP 로 바로 SSH 가 된다.

```
[클라이언트]
    |
    +--> Nginx 리버스 프록시 캐시 (:80)     ---+   cache VM
    |                                          |
    +--> Squid 포워드 프록시 캐시 (:3128)   ---+
                                               |
                                               v
                              Flask 앱 (:5000) <--> Redis (:6379)   webserver VM
                                               |    (Cache-Aside)
                                               v
                              데이터 소스 (느린 조회, 약 2초)
```

**학습 대상은 자동화하지 않는다.** 패키지만 설치하고, 앱 코드 배치와 캐시 설정은 남겨 둔다.

## 1. 만들어지는 것

| 리소스 | 값 |
|---|---|
| 네트워크 | **새로 만들지 않는다.** 기존 공용 Shared Network 를 `shared_network_id` 로 지정 |
| webserver | `python3-pip`, `python3-flask`, `python3-redis`, `redis-server` 설치 |
| cache | `nginx`, `squid` 설치 |
| IP | Shared Network DHCP 로 `10.0.X.X`. cache 의 `/etc/dku-lab-backends` 에 webserver IP 기록 |
| 접속 | VPN 연결 후 `ssh ubuntu@10.0.X.X` |

옵션 변수로 사전 구성 범위를 넓힐 수 있다.

| 변수 | 기본값 | true 로 두면 |
|---|---|---|
| `preinstall_app_code` | `false` | `app.py` 를 `/home/ubuntu/backend-app/` 에 배치하고 `backend-app.service` 로 기동 |
| `preinstall_cache_config` | `false` | Nginx 캐시 존(`/etc/nginx/conf.d/api-cache-zone.conf`) + `backend-proxy` 설정 + Squid `cache_dir` 배치 |
| `redis_password` | `""` | `bind 127.0.0.1 ::1` 과 `requirepass` 를 redis.conf 에 추가하고 앱에도 전달 |

배치되는 파일은 모두 `files/` 안의 원본을 그대로 쓴다
(저장소의 `week05-cache/` 와 동일한 `app.py`, `nginx-cache.conf`, `squid.conf.snippet`).

## 2. 전제

- 로컬에 Terraform 1.0 이상, **VPN 연결**.
- CloudStack API Key / Secret Key. **발급 위치: 우측 상단 프로필 > 사용자 상세 > API 키 생성.**
- 컴퓨트 오퍼링 이름은 확인됨: `Small`(1core/2GB) · `Medium`(2core/4GB) · `Large`(4core/8GB) · `XLarge`(8core/16GB) · `Custom`.
- **공용 Shared Network 의 UUID 가 필요하다.** provider 0.5.0 에는 네트워크를 이름으로 찾는
  data source 가 없다. 콘솔 `[네트워크]` 상세 화면의 ID 를 복사한다.
  **실제 네트워크 이름은 확인됨: `Shared Network`**(CIDR `10.0.0.0/16`, 게이트웨이 `10.0.0.1`).
- 트래픽 포트(백엔드 `5000`, Nginx `80`, Squid `3128`)는 별도 CloudStack 방화벽 리소스를 만들지 않는다.
  Shared Network 는 내부망이라 접속 자체가 VPN(대역 `10.8.0.0/24`)으로 제한되고, `5000` 은 외부에 노출하지 않는다.

## 3. 실행

```bash
cp terraform.tfvars.example terraform.tfvars   # api_key / secret_key / shared_network_id
terraform init
terraform plan
terraform apply
terraform output
```

캐시 효과만 빠르게 재측정하려면 사전 구성까지 자동화한다.

```bash
terraform apply -var preinstall_app_code=true -var preinstall_cache_config=true
```

## 4. 출력값으로 접속

```bash
terraform output ssh_webserver     # ssh ubuntu@10.0.X.X
terraform output ssh_cache
terraform output backend_url        # http://10.0.X.X:5000/api/products
terraform output nginx_cache_url    # http://10.0.X.X/api/products
terraform output squid_proxy        # http://10.0.X.X:3128

$(terraform output -raw ssh_cache)
```

## 5. 검증용 명령 모음

```bash
./verify.sh          # 각 항목 3회 측정
./verify.sh 5        # 각 항목 5회 측정
SSHPASS=ubuntu ./verify.sh
```

결과는 `verify-out/w5-<타임스탬프>.txt` 에 저장된다.

손으로 확인할 때 (가이드 Part 별 명령):

```bash
# --- webserver VM ---
# 원본 응답 시간 (약 2초)
time curl http://localhost:5000/api/products

# Redis 기본
redis-cli PING                       # PONG (requirepass 를 걸면 NOAUTH)
redis-cli -a '<비밀번호>' PING
redis-cli SET k v ; redis-cli GET k
redis-cli SETEX t 30 v ; redis-cli TTL t

# Cache-Aside (TTL 10초) - 1회 database, 2회 redis
time curl http://localhost:5000/api/products-cached
time curl http://localhost:5000/api/products-cached
redis-cli TTL products:all           # 0 이상의 정수 (-2 면 키 없음)

systemctl status backend-app
sudo journalctl -u backend-app -n 20 --no-pager

# --- cache VM ---
sudo nginx -t
# Nginx 캐시 HIT/MISS (2회째 HIT)
curl -I http://localhost/api/products
curl -I http://localhost/api/products
curl -I "http://localhost/api/products?nocache=1"     # 항상 MISS
time curl -I http://localhost/api/products

# 캐시 파일 (levels=1:2 구조)
sudo ls -lR /var/cache/nginx/api_cache/

# stale 캐시 (백엔드 중지 후 TTL 만료 뒤) -> X-Cache-Status: STALE, 200 유지
curl -I http://localhost/api/products

# Squid 포워드 프록시
time curl --proxy http://localhost:3128 http://<webserver IP>:5000/api/products
sudo tail -10 /var/log/squid/access.log     # TCP_MISS/200 -> TCP_MEM_HIT/200

# 이중 캐싱 (Nginx 10초 + Redis 30초)
curl -I http://localhost/api/products-dual | grep -i x-cache
time curl http://localhost/api/products-dual
```

이중 캐싱 시점별 기대 동작 (Nginx 10초, Redis 30초, DB 조회 2초)

| 시점 | Nginx | Redis | 응답 시간 |
|---|---|---|---|
| 0초 | MISS | MISS | 약 2초 (DB 조회 -> Redis 저장 -> Nginx 저장) |
| 1~9초 | HIT | 조회 없음 | 약 0.01초 |
| 10~29초 | MISS | HIT | 약 0.02초 |
| 30초 이후 | MISS | MISS | 약 2초 |

### 캐시 비우고 다시 측정 (파괴적)

`verify.sh` 는 캐시를 지우지 않는다. 완전한 MISS -> HIT 비교가 필요하면 직접 실행한다.

```bash
sudo rm -rf /var/cache/nginx/api_cache/*      # cache VM: Nginx 캐시 삭제
redis-cli DEL products:all                    # webserver VM: 실습 키만 삭제
# FLUSHALL 은 쓰지 않는다. 다른 키까지 모두 지운다.
```

## 6. destroy 주의

```bash
terraform destroy
```

- **되돌릴 수 없다.** `expunge = true` 이므로 2대 VM 과 디스크가 즉시 완전 삭제된다.
- **공용 Shared Network 는 이 코드가 만들지 않았으므로 destroy 해도 지워지지 않는다.**
  콘솔에서 이 네트워크를 직접 지우지 않는다.
- 검증 결과(`verify-out/`)를 먼저 확보한다.
- `redis_password` 를 썼다면 실습이 끝나고 그 값을 폐기한다. `terraform.tfvars` 와
  `terraform.tfstate` 에 남으므로 두 파일 모두 커밋하지 않는다(`.gitignore` 대상).
- 실습이 끝나면 반드시 destroy 한다. 컴퓨트 자원이 계속 점유된다.

## 7. 알아 둘 점

- cloud-init 은 파일 내용을 `encoding: b64` 로 넣는다. `app.py` 의 파이썬 코드와 nginx 설정의
  `$upstream_cache_status` 같은 변수가 YAML 처리로 훼손되지 않게 하려는 것이다.
- `preinstall_cache_config = true` 는 캐시 존을 `nginx.conf` 대신
  `/etc/nginx/conf.d/api-cache-zone.conf` 에 둔다. Ubuntu 의 `nginx.conf` 가 http 블록에서
  `conf.d/*.conf` 를 include 하므로 결과는 같다. 가이드는 `nginx.conf` 를 직접 고치는 방법을
  가르치므로, 학생 실습과 강사 검증의 경로가 다를 수 있다는 점만 알고 있으면 된다.
- Squid 는 응답에 캐싱 가능한 `Cache-Control` 이 있어야 캐시한다. 가이드 Part 1 의
  `public, max-age=10` 헤더가 붙는 경로로 확인한다.
- Redis 설정 파일 경로는 `/etc/redis/redis.conf` 다(Ubuntu/Debian `redis-server` 패키지의 고정 경로). 2026-08-23에 이 플랫폼 VM에 실제로 `redis-server 7.0.15`를 설치해 확인했으나, `/etc/redis/` 디렉터리가 `ubuntu` 계정에는 읽기 권한이 없어(`Permission denied`) 파일 존재 자체를 직접 `ls`로는 못 봤다. 패키지 규격상 이 경로가 맞다는 확신은 높지만, `sudo`로 최종 확인은 안 됐다.

## 강사 검증 환경 (참고)

| 항목 | 값 |
|---|---|
| 콘솔 | https://dku.kloud.zone |
| 계정 | hyungwook.yu (학생은 학번) |
| Domain | CE |
| API 엔드포인트 | https://dku.kloud.zone/client/api |

학생 배포용 문서에는 계정을 학번 기준으로 적어 두었다. 강사 계정은 학번 형식이 아니므로,
실습 자료의 로그인 예시와 다를 수 있다는 점만 유의한다.
