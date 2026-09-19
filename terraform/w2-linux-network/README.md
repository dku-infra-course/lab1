# W2 실습 환경 (Terraform) - 리눅스 기본과 네트워크 확인

2주차 실습 가이드 `실습_W2_리눅스네트워크.html` 검증용 환경이다.
**기존 공용 Shared Network 에 순수 Ubuntu VM 을 올린다.** VPN 을 켜면 사설 IP(`10.0.X.X`)로
바로 SSH 가 되므로 포트포워딩·방화벽 설정이 필요 없다.

**학습 대상은 자동화하지 않는다.** Apache 설치와 페이지 교체는 실습에서 학생이 직접 하므로
cloud-init 에 넣지 않았다. 검증 스크립트도 Apache 가 없으면 "설치되지 않았다" 로 보고한다.

## 1. 만들어지는 것

| 리소스 | 값 |
|---|---|
| 네트워크 | **새로 만들지 않는다.** 기존 공용 Shared Network 를 `shared_network_id` 로 지정해 붙인다 |
| VM | `web01-<name_prefix>`, 선택적으로 `web02-<name_prefix>` (Ubuntu_24.04, Medium, 20GB) |
| IP | Shared Network DHCP 로 `10.0.X.X` 할당. 고정하지 않는다 |
| 접속 | VPN 연결 후 `ssh ubuntu@10.0.X.X` |

## 2. 전제

- 로컬에 Terraform 1.0 이상.
- **VPN 연결.** VPN 을 켜면 Solid Cloud 내부망(게이트웨이 `10.0.0.1`)으로 들어가며,
  Shared Network 에 올린 VM 의 사설 IP 로 직접 SSH 가 된다.
- CloudStack API Key / Secret Key. **발급 위치: 우측 상단 프로필 > 사용자 상세 > API 키 생성.**
- 컴퓨트 오퍼링 이름(`service_offering_name`)은 확인됨: `Small`(1core/2GB) · `Medium`(2core/4GB) · `Large`(4core/8GB) · `XLarge`(8core/16GB) · `Custom`.

## 3. 공용 Shared Network ID 확인 (필수)

`shared_network_id` 는 기본값이 없다. 반드시 지정해야 한다.
provider 0.5.0 에는 네트워크를 이름으로 찾는 data source 가 없어서(제공되는 data source 는
zone / ipaddress / instance / network_offering / pod / ssh_keypair / service_offering /
template / user / vpc / vpn_connection / volume) ID 를 직접 받는다.

확인 방법 중 하나를 쓴다.

1. 콘솔 `[네트워크]` 목록에서 공용 네트워크를 열고, 상세 화면의 **ID** 값을 복사한다.
   (주소창 URL 에도 같은 UUID 가 들어 있다.)
2. CloudMonkey 를 쓸 수 있으면:
   ```bash
   cmk list networks listall=true filter=id,name,type,cidr
   ```

**실제 공용 네트워크 이름은 확인됨: `Shared Network`(CIDR `10.0.0.0/16`, 게이트웨이 `10.0.0.1`).** `terraform.tfvars.example` 에 ID·이름을 채워 두었다.

```bash
cp terraform.tfvars.example terraform.tfvars
# shared_network_id 를 채운다
```

## 4. 실행

```bash
terraform init
terraform plan
terraform apply
terraform output
```

## 5. 출력값으로 접속

```bash
terraform output ssh_web01        # 예: ssh ubuntu@10.0.3.42
terraform output web01_private_ip

$(terraform output -raw ssh_web01)
```

계정 `ubuntu` / 비밀번호 `ubuntu`. 키쌍을 쓰려면 `ssh_keypair_name` 을 지정한다.

## 6. 검증용 명령 모음

```bash
./verify.sh                # web01
./verify.sh --web02        # web02 까지
SSHPASS=ubuntu ./verify.sh
```

결과는 `verify-out/w2-<타임스탬프>.txt` 에 저장된다.

손으로 확인할 때 (가이드의 실제 명령):

```bash
ssh ubuntu@<사설IP>

# 1) 서버 스펙
lscpu
lscpu | grep -E 'Architecture|^CPU\(s\)|Thread|Core|Socket|Model name|Hypervisor'
nproc
free -h
df -h ; df -h /
lsblk
systemd-detect-virt

# 2) 리눅스 기본
uname -a
grep PRETTY_NAME /etc/os-release
whoami ; id ; sudo whoami
awk -F: '$3>=1000 && $3<65534 {print $1, $3, $6}' /etc/passwd

# 3) 서비스 상태
systemctl status ssh --no-pager
systemctl is-enabled ssh
systemctl list-units --type=service --state=running
sudo journalctl -u ssh -n 10 --no-pager

# 4) 네트워크
ip a ; ip -br addr ; ip route
ss -tulpn
sudo ss -tlnp
ping -c 3 <게이트웨이>
cat /etc/resolv.conf ; resolvectl status | head -20
getent hosts ubuntu.com
curl -I https://ubuntu.com

# 5) Apache (여기부터는 실습에서 직접 한다)
sudo apt update
sudo apt install -y apache2
apache2 -v
echo "<h1>DKU Infra W2 - $(hostname)</h1>" | sudo tee /var/www/html/index.html
sudo systemctl enable --now apache2
systemctl is-enabled apache2 ; systemctl is-active apache2
curl -I localhost ; curl -s localhost
sudo ss -tlnp | grep ':80'

# 6) 두 대 사이 사설 IP 통신 (create_web02 = true 일 때)
curl -s http://<web02 사설IP>
```

통과 기준

| 확인 항목 | 명령 | 통과 기준 |
|---|---|---|
| vCPU 수 | `nproc` | 콘솔의 컴퓨트 오퍼링과 일치 |
| 메모리 | `free -h` | 오퍼링 값과 근사 |
| 디스크 | `df -h /` | `root_disk_size`(20GB)와 근사 |
| 인터페이스명 | `ip -br addr` | `ens3` 등. W3 의 IFACE 값으로 기록 |
| 기본 게이트웨이 | `ip route` | `default via <GW> dev <IFACE>` |
| 게이트웨이 도달 | `ping -c 3 <GW>` | 3 received |
| 외부 통신 | `curl -I https://ubuntu.com` | 200 또는 301 |
| SSH 리스닝 | `ss -tulpn` | `:22` LISTEN |
| Apache 리스닝 | `ss -tulpn \| grep :80` | 설치 후 `:80` LISTEN |
| Apache 자동 시작 | `systemctl is-enabled apache2` | `enabled` |

## 7. destroy 주의

```bash
terraform destroy
```

- **되돌릴 수 없다.** `expunge = true` 이므로 VM 과 디스크가 즉시 완전 삭제된다.
- **공용 Shared Network 는 이 코드가 만들지 않았으므로 destroy 해도 지워지지 않는다.**
  다른 사람 VM 이 함께 붙어 있는 공용 네트워크이므로, 콘솔에서 이 네트워크를 직접 지우지 않는다.
- destroy 전에 `verify-out/` 결과를 확보한다.
- 실습이 끝나면 반드시 destroy 한다. 컴퓨트 자원이 계속 점유된다.

## 강사 검증 환경 (참고)

| 항목 | 값 |
|---|---|
| 콘솔 | https://dku.kloud.zone |
| 계정 | hyungwook.yu (학생은 학번) |
| Domain | CE |
| API 엔드포인트 | https://dku.kloud.zone/client/api |

학생 배포용 문서에는 계정을 학번 기준으로 적어 두었다. 강사 계정은 학번 형식이 아니므로,
실습 자료의 로그인 예시와 다를 수 있다는 점만 유의한다.
