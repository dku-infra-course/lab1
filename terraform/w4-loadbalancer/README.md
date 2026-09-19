# W4 실습 환경 (Terraform) - Nginx 리버스 프록시와 로드밸런싱

4주차 실습 가이드 `실습_W4_로드밸런싱.html` 검증용 환경이다.
**기존 공용 Shared Network 에 3대(lb / web01 / web02)를 올린다.** VPN 을 켜면
사설 IP 로 바로 SSH 가 되고, lb 는 내부 IP 로 백엔드에 `curl` 한다.

**학습 대상은 자동화하지 않는다.** 기본값(`preinstall_packages = false`, `preinstall_lb_config = false`)은
세 VM 모두 패키지조차 설치하지 않은 순정 Ubuntu다. 학생이 콘솔로 직접 만드는 VM과 조건을 맞추기
위한 것이고, 녹화·직접 실습 목적으로는 이 기본값을 그대로 쓴다.

- `preinstall_packages = true`: 백엔드에는 Apache 와 서버 구분 페이지, lb 에는 Nginx 를 설치만 한다.
  upstream 블록, `weight`, `least_conn`, `ip_hash`, `max_fails`/`fail_timeout`(수동 헬스체크),
  `stream`(L4) 설정은 여전히 실습에서 직접 한다.
- `preinstall_lb_config = true`: 패키지 설치까지 포함해서 lb 의 upstream 설정까지 배치한다.

## 1. 만들어지는 것

| 리소스 | 값 |
|---|---|
| 네트워크 | **새로 만들지 않는다.** 기존 공용 Shared Network 를 `shared_network_id` 로 지정 |
| web01 | Apache, 페이지 `Web Server 01` |
| web02 | Apache, 페이지 `Web Server 02` (리버스 프록시 `/admin` 실습에서는 `Administrator Page` 로 변경) |
| lb | Nginx **설치만** |
| IP | Shared Network DHCP 로 `10.0.X.X` 할당. 각 VM 의 `/etc/dku-lab-backends` 에 백엔드 IP 를 기록해 둔다 |
| 접속 | VPN 연결 후 `ssh ubuntu@10.0.X.X` |

## 2. 전제

- 로컬에 Terraform 1.0 이상, **VPN 연결**.
- CloudStack API Key / Secret Key. **발급 위치: 우측 상단 프로필 > 사용자 상세 > API 키 생성.**
- 컴퓨트 오퍼링 이름은 확인됨: `Small`(1core/2GB) · `Medium`(2core/4GB) · `Large`(4core/8GB) · `XLarge`(8core/16GB) · `Custom`.
- **공용 Shared Network 의 UUID 가 필요하다.** provider 0.5.0 에는 네트워크를 이름으로 찾는
  data source 가 없어서 ID 를 변수로 받는다. 콘솔 `[네트워크]` 상세 화면의 ID 를 복사하거나
  `cmk list networks listall=true filter=id,name,type` 로 확인한다.
  **실제 네트워크 이름은 확인됨: `Shared Network`**(CIDR `10.0.0.0/16`, 게이트웨이 `10.0.0.1`, `terraform.tfvars.example` 에 채워 두었다).

## 3. 실행

```bash
cp terraform.tfvars.example terraform.tfvars   # api_key / secret_key / shared_network_id
terraform init
terraform plan
terraform apply
terraform output
```

LB 설정까지 한 번에 올리려면:

```bash
terraform apply -var preinstall_lb_config=true
```

이때 `files/nginx-lb.conf`(labs 저장소의 원본과 동일)의 `{{WEB01_IP}}` / `{{WEB02_IP}}` 가
실제 할당 IP 로 치환되어 `/etc/nginx/sites-available/http-lb` 에 배치된다.

## 4. 출력값으로 접속

```bash
terraform output ssh_lb           # ssh ubuntu@10.0.X.X
terraform output ssh_web01
terraform output ssh_web02
terraform output lb_url           # http://10.0.X.X/

$(terraform output -raw ssh_lb)
```

## 5. 검증용 명령 모음

```bash
./verify.sh                   # 반복 10회, 읽기 전용
./verify.sh 20                # 반복 20회
./verify.sh 10 --failover     # apache2 중지로 페일오버 확인 후 자동 복구
SSHPASS=ubuntu ./verify.sh
```

결과는 `verify-out/w4-<타임스탬프>.txt` 에 저장된다.

기본 상태(`preinstall_packages = false`, `preinstall_lb_config = false`, 패키지도 안 깔린 순정 Ubuntu)에서
lb 에 손으로 설정하는 순서(`sudo apt install -y nginx curl` 부터 시작한다):

```bash
ssh ubuntu@<lb IP>
cat /etc/dku-lab-backends          # web01 / web02 IP 확인

sudo apt update && sudo apt install -y git
git clone https://github.com/dku-infra-course/labs.git   # 저장소 URL: 확인 필요
cd labs/week04-loadbalancer

sed -e "s/{{WEB01_IP}}/<web01 IP>/g" -e "s/{{WEB02_IP}}/<web02 IP>/g" \
    nginx-lb.conf | sudo tee /etc/nginx/sites-available/http-lb

sudo ln -s /etc/nginx/sites-available/http-lb /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

확인 명령:

```bash
# 설정 문법
sudo nginx -t
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 분산 (반복 호출)
for i in $(seq 1 10); do curl -s http://<lb IP>/; sleep 1; done

# L4 stream (심화, 8080 을 구성한 경우)
for i in $(seq 1 10); do curl -s http://<lb IP>:8080/; sleep 1; done

# 백엔드 직접 vs 프록시 경유 (투명성)
curl -s http://<web02 IP>/
curl -s http://<lb IP>/

# 클라이언트 IP 전달
sudo tail -f /var/log/apache2/access.log      # 백엔드에서, X-Real-IP 확인

# 페일오버
ssh ubuntu@<web01 IP> 'sudo systemctl stop apache2'
for i in $(seq 1 10); do curl -s http://<lb IP>/; done   # web02 만 응답
ssh ubuntu@<web01 IP> 'sudo systemctl start apache2'     # 복구

# 알고리즘 바꿔 보기 (upstream 블록 맨 위에 추가)
#   least_conn;   또는   ip_hash;
sudo nginx -t && sudo systemctl reload nginx
```

통과 기준

| 확인 | 기대 결과 |
|---|---|
| 설정 문법 | `nginx -t` 가 ok / successful |
| 분산 | 응답이 두 백엔드 사이에서 번갈아 나타난다. `weight 3:1` 이면 web01 이 약 3배 |
| 페일오버 | 백엔드 1대를 중지해도 LB 경유 요청이 오류 없이 처리된다 |
| 투명성 | 백엔드 직접 응답과 프록시 경유 응답 본문이 같다 |
| 클라이언트 IP | 백엔드 `access.log` 에 `X-Real-IP` 로 실제 IP 가 남는다 |

Nginx 오픈소스는 `max_fails` / `fail_timeout` 의 **수동(passive) 헬스체크만** 제공한다.
주기적 프로브(`health_check` 지시어)는 Nginx Plus 기능이다.

## 6. destroy 주의

```bash
terraform destroy
```

- **되돌릴 수 없다.** `expunge = true` 이므로 3대 VM 과 디스크가 즉시 완전 삭제된다.
- **공용 Shared Network 는 이 코드가 만들지 않았으므로 destroy 해도 지워지지 않는다.**
  다른 사람 VM 이 함께 붙어 있으니 콘솔에서 이 네트워크를 직접 지우지 않는다.
- `./verify.sh --failover` 가 중간에 끊겼다면 web01 의 Apache 가 정지 상태로 남을 수 있다.
  계속 쓸 계획이면 `sudo systemctl start apache2` 로 복구한다.
- 검증 결과(`verify-out/`)를 먼저 확보하고 destroy 한다.
- 실습이 끝나면 반드시 destroy 한다. 컴퓨트 자원이 계속 점유된다.

## 7. 알아 둘 점

- IPVS / LVS 심화(B3)는 VIP `192.168.0.100` 을 쓴다. Shared Network 대역은 `10.0.X.X`
  이므로 이 코드에 있는 별도 토글(`enable_ipvs_lab`, 8절)로 격리 네트워크를 새로 만들어 진행한다.
  3주차 환경을 이어 쓰지 않는다. 3주차는 이미 destroy 했을 수 있기 때문이다.
- 백엔드는 Apache, 앞단은 Nginx 다. 서로 다른 소프트웨어를 쓰는 것이 정상이다.
- cloud-init 은 파일 내용을 `encoding: b64` 로 넣는다. nginx 설정의 `$host` 같은 변수가
  YAML 처리 과정에서 훼손되지 않도록 하기 위한 것이다.

## 8. 선택·심화 B3(IPVS/LVS): 별도 격리 네트워크

기본값(`enable_ipvs_lab = false`)에서는 아래 리소스가 전혀 만들어지지 않는다.
본 실습(web01·web02·lb, Shared Network)에는 영향이 없다. `terraform plan` 만 해 봐도 변경 사항이 없다.

3주차 것을 이어 쓰지 않고 매번 새로 만든다. 이미 3주차를 destroy 한 뒤에 4주차를 진행하는
경우를 기준으로 한다.

```bash
terraform apply -var enable_ipvs_lab=true
```

만들어지는 것

| 리소스 | 값 |
|---|---|
| 네트워크 | 새 격리 네트워크. CIDR `192.168.0.0/24` (3주차와 같은 대역, 가이드의 VIP `192.168.0.100` 과 맞는다) |
| ipvs-web01 | `192.168.0.10`, Apache |
| ipvs-web02 | `192.168.0.11`, Apache |
| ipvs-director | `192.168.0.20`, 패키지 미설치 (`ipvsadm` 설치·모듈 로드·VIP 구성이 실습 대상이다) |
| 접속 | 공인 IP(Source NAT) + 포트포워딩. web01 `2201`, web02 `2202`, director `2203` |
| 컴퓨트 오퍼링 | `ipvs_service_offering_name` (기본값 `Small`). 본 실습(Medium)과 분리했다: B3는 Web IDE를 쓰지 않고 IPVS/LVS 자체도 가벼운 작업이라 Medium이 필요 없다. 학생 쿼터를 아낀다 |

```bash
terraform output ssh_ipvs_director
terraform output ssh_ipvs_web01
terraform output ssh_ipvs_web02
```

- 격리 네트워크 아웃바운드는 기본적으로 막혀 있어 tcp 80/443, udp 53, icmp 만 열어 뒀다.
  `apt install` 은 이 규칙으로 된다.
- SSH 인바운드 허용 대역은 `ssh_allowed_cidr` 로 좁힐 수 있다(기본값 `0.0.0.0/0`).
- 정리할 때는 본 실습과 마찬가지로 `terraform destroy` 한 번으로 같이 지워진다.
  상태(state)에 있는 리소스를 지우는 것이라 `-var enable_ipvs_lab=true` 를 따로 줄 필요는 없다.

## 강사 검증 환경 (참고)

| 항목 | 값 |
|---|---|
| 콘솔 | https://dku.kloud.zone |
| 계정 | hyungwook.yu (학생은 학번) |
| Domain | CE |
| API 엔드포인트 | https://dku.kloud.zone/client/api |

학생 배포용 문서에는 계정을 학번 기준으로 적어 두었다. 강사 계정은 학번 형식이 아니므로,
실습 자료의 로그인 예시와 다를 수 있다는 점만 유의한다.
