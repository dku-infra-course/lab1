# week04 · Nginx 리버스 프록시와 로드밸런싱

실습 가이드: `실습_W4_로드밸런싱.html`

## 1. 목표

- Nginx를 **리버스 프록시** 로 세워 단일 진입점을 만든다.
- `upstream` 블록으로 백엔드 2대에 **L7 로드밸런싱** 을 적용하고, `weight` · `least_conn` · `ip_hash` 의 차이를 확인한다.
- Nginx 오픈소스의 **수동(passive) 헬스체크** 로 장애 서버가 배제되는 것을 확인한다.
- (선택) `stream` 블록으로 **L4 로드밸런싱**, IPVS·HAProxy 심화까지 확장한다.

## 2. 사전 조건

| 역할 | 가이드 표기 | 자리표시자 | IP 할당 | 설치 대상 |
|---|---|---|---|---|
| 백엔드 웹서버 1 | `web01-{{STUDENT_ID}}` | `{{WEB01_IP}}` | Shared Network DHCP(`10.0.X.X`) | Apache |
| 백엔드 웹서버 2 | `web02-{{STUDENT_ID}}` | `{{WEB02_IP}}` | Shared Network DHCP(`10.0.X.X`) | Apache |
| 로드밸런서 | `lb-{{STUDENT_ID}}` | `{{LB_IP}}` | Shared Network DHCP(`10.0.X.X`) | Nginx |
| IPVS 가상 IP (심화, B3) | | `{{VIP}}` | `192.168.0.100`(B3 전용 격리 네트워크에서만) | |

- 세 VM은 같은 **기본 Shared Network**에 있고 사설 IP(`10.0.X.X`)로 서로 통신되어야 한다. IP는 고정하지 않고 DHCP로 받은 값을 `terraform output` 또는 콘솔에서 그때그때 확인한다.
- 백엔드는 **Apache**, 앞단 로드밸런서는 **Nginx** 다. 서로 다른 소프트웨어를 쓰는 것이 정상이다.
- IPVS 심화(B3)는 이번 주 본 실습(web01·web02·lb)과 별개의 **격리 네트워크**(CIDR `192.168.0.0/24`)에서 진행한다. 3주차 환경을 이어 쓰지 않고 새로 만든다.
- Shared Network는 VPN 연결 상태에서 사설 IP로 바로 접속되므로, 본 실습에는 포트포워딩·방화벽 규칙이 필요 없다.

## 3. 파일

| 파일 | 설명 |
|---|---|
| `nginx-lb.conf` | `/etc/nginx/sites-available/http-lb` 원본. upstream(weight 3:1, passive 헬스체크) + server 블록. 하단 주석에 `stream`(L4) 예시 포함 |
| `backend-index.html` | 백엔드 구분용 `/var/www/html/index.html` 템플릿 (`{{SERVER_LABEL}}` 치환) |
| `install-backend.sh` | 백엔드 VM에 Apache 설치 + 구분용 페이지 작성 |
| `verify-lb.sh` | 반복 요청 분산 집계, 백엔드 직접/프록시 경유 비교, 페일오버 안내 (읽기 전용) |

## 4. 실행 순서

### 4-1. 백엔드 2대 구성

두 백엔드 VM에서 각각:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs/week04-loadbalancer
chmod +x *.sh
```

web01 에서:

```bash
./install-backend.sh web01          # 페이지: Web Server 01
```

web02 에서:

```bash
./install-backend.sh web02          # 페이지: Administrator Page
```

L4 Stream 분산을 눈으로 확인하는 단계(B2)에서는 web02 페이지를 바꾼다.

```bash
./install-backend.sh web02 "Web Server 02"
```

### 4-2. 로드밸런서 구성

Nginx VM 에서:

```bash
sudo apt update && sudo apt install -y nginx git
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs/week04-loadbalancer

# 자리표시자를 본인 환경 값(콘솔 또는 terraform output으로 확인한 실제 사설 IP)으로 치환하여 배치
sed -e 's/{{WEB01_IP}}/<web01 실제 사설 IP>/g' \
    -e 's/{{WEB02_IP}}/<web02 실제 사설 IP>/g' \
    nginx-lb.conf | sudo tee /etc/nginx/sites-available/http-lb

# 활성화 (기존 default 링크는 해제)
sudo ln -s /etc/nginx/sites-available/http-lb /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl reload nginx
```

`nginx -t` 가 아래처럼 나오면 정상이다.

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 4-3. 알고리즘 바꿔 보기

`nginx-lb.conf` 의 `upstream` 블록 맨 위 주석을 해제한다.

```nginx
upstream webservers {
    least_conn;      # 또는 ip_hash;
    server {{WEB01_IP}}:80 weight=3 max_fails=3 fail_timeout=10s;
    server {{WEB02_IP}}:80 weight=1 max_fails=3 fail_timeout=10s;
}
```

수정 후 항상 `sudo nginx -t && sudo systemctl reload nginx`.

## 5. 검증 방법

```bash
chmod +x verify-lb.sh
./verify-lb.sh 10
```

또는 직접:

```bash
for i in {1..10}; do curl http://{{LB_IP}}; sleep 1; done         # L7 upstream
for i in {1..10}; do curl http://{{LB_IP}}:8080; sleep 1; done    # L4 stream
curl http://{{WEB02_IP}}/     # 백엔드 직접
curl http://{{LB_IP}}/        # 프록시 경유 (동일 응답)
```

통과 기준

| 확인 | 기대 결과 |
|---|---|
| 분산 | 응답이 두 백엔드 사이에서 번갈아 나타나고, weight 3:1 비율대로 web01이 더 자주 관측된다 |
| 페일오버 | 백엔드 1대의 `apache2` 를 중지해도 Nginx 경유 요청이 오류 없이 처리된다 |
| 투명성 | 백엔드 직접 응답과 프록시 경유 응답의 본문이 동일하다 |
| 클라이언트 IP | 백엔드 `access.log` 에 `X-Real-IP` 로 실제 클라이언트 IP가 남는다 |
| IPVS 한계(심화) | IPVS는 헬스체크가 없어 장애 서버로도 계속 분산되어 일부 요청이 실패한다 |

## 6. 정리 (rollback)

이번 주 확인이 끝났으면 VM(web01·web02·lb)을 정리(Destroy)한다. 기본 Shared Network는 이 실습이 만든 것이 아니므로 삭제되지 않는다(다른 학생과 같이 쓰는 자원이니 직접 지우지 않는다). 5주차는 이 환경을 이어 쓰지 않고 새로 만든다.

IPVS 심화(B3)를 별도 격리 네트워크에서 진행했다면 그 네트워크·VM 3대도 함께 정리한다.

```bash
sudo ipvsadm -C
sudo ip addr del 192.168.0.100/32 dev ens3
```
