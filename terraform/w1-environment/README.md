# W1 실습 환경 (Terraform) - 격리 네트워크와 첫 VM

1주차 실습 가이드 `실습_W1_환경준비.html` 의 결과 상태를 Terraform 으로 재현한다.
학생이 콘솔에서 손으로 하는 작업(격리 네트워크 생성, VM 배포, Egress, 포트포워딩, 방화벽)을
코드로 만들어 두고, 강사가 SSH 로 접속해 가이드의 확인 명령이 실제로 통하는지 검증한다.

**학습 대상은 자동화하지 않는다.** VM 안에는 아무 패키지도 설치하지 않는다.
Apache 설치와 페이지 교체는 W2 실습에서 학생이 직접 한다.

## 1. 만들어지는 것

| 리소스 | 값 |
|---|---|
| 격리 네트워크 | `tf-<name_prefix>-net`, CIDR `192.168.0.0/24`, 오퍼링 `DefaultIsolatedNetworkOfferingWithSourceNatService` |
| VM | `web01-<name_prefix>` (`192.168.0.10`), 선택적으로 `web02-<name_prefix>` (`192.168.0.11`) |
| 접속 | 가상 라우터 공용 IP 의 `2201` -> web01 `22`, (선택) `2202` -> web02 `22` |
| 방화벽 | 인바운드 `2201`(및 `2202`) 를 `ssh_allowed_cidr` 에만 개방 |
| Egress | 아웃바운드 TCP 80/443, UDP 53, ICMP 허용 (없으면 `apt update` 가 실패한다) |

## 2. 전제

- 로컬에 Terraform 1.0 이상.
- **VPN 연결.** Solid Cloud API 엔드포인트와 VM 은 교내망/VPN 에서만 닿는다. 실습 내내 유지한다.
- CloudStack API Key / Secret Key. **발급 위치: 우측 상단 프로필 > 사용자 상세 > API 키 생성.**
- 자격증명은 코드에 넣지 않는다.
  ```bash
  cp terraform.tfvars.example terraform.tfvars   # 파일로 넣는 방법 (.gitignore 대상)
  # 또는
  export TF_VAR_api_key="..." ; export TF_VAR_secret_key="..."
  ```
- 컴퓨트 오퍼링 이름(`service_offering_name`)은 확인됨: `Small`(1core/2GB) · `Medium`(2core/4GB) · `Large`(4core/8GB) · `XLarge`(8core/16GB) · `Custom`.
  Web IDE 를 쓸 계획이면 Medium 이상, K8s 는 Large 를 권장한다.
- 방화벽 Source CIDR 로 쓸 **VPN 대역은 `10.8.0.0/24`(넷마스크 `255.255.255.0`)로 확인됨.** 기본값은 실습에서 직접 좁혀 보도록 `0.0.0.0/0` 으로 열려 있으니, 확인이 끝나면 이 대역으로 좁히는 것을 권장한다.

## 3. 실행

```bash
terraform init
terraform plan
terraform apply          # 확인 후 yes
terraform output
```

`terraform apply` 후 VM 이 `Running` 이 되고 cloud-init 이 끝날 때까지 30초에서 1분 정도 걸린다.
바로 SSH 가 안 되면 잠시 기다린 뒤 다시 시도한다.

## 4. 출력값으로 접속

```bash
terraform output ssh_web01        # 예: ssh -p 2201 ubuntu@203.0.113.10
terraform output source_nat_ip    # 가이드의 {{PUBLIC_IP}} 값
terraform output port_check_web01 # nc -vz <공인IP> 2201

$(terraform output -raw ssh_web01)
```

기본 계정은 `ubuntu`, 비밀번호는 `ubuntu` 다(변수 `vm_password`).
콘솔에 등록한 SSH 키쌍을 쓰려면 `ssh_keypair_name` 변수에 키쌍 이름을 넣는다.

## 5. 검증용 명령 모음

한 번에 돌리려면:

```bash
./verify.sh                # web01
./verify.sh --web02        # web02 까지 (create_web02 = true 로 apply 한 경우)
SSHPASS=ubuntu ./verify.sh # sshpass 가 있으면 비밀번호 입력 자동화
```

결과는 `verify-out/w1-<타임스탬프>.txt` 에 저장된다.

손으로 확인할 때 쓰는 명령(가이드의 핵심 확인 항목):

```bash
# 로컬에서: 포트가 열렸는지
nc -vz <가상라우터-공용-IP> 2201
# Windows PowerShell
# Test-NetConnection <가상라우터-공용-IP> -Port 2201

# 접속
ssh -p 2201 ubuntu@<가상라우터-공용-IP>

# VM 안에서
whoami                     # ubuntu
hostname                   # web01-<name_prefix>
ip -br addr                # ens3 에 192.168.0.10/24
ip -4 addr show ens3
ip route                   # default via 192.168.0.1 dev ens3
sudo ss -tlnp              # 0.0.0.0:22 LISTEN
systemctl status ssh --no-pager
ping -c 3 192.168.0.1      # 게이트웨이(가상 라우터) 도달
getent hosts ubuntu.com    # DNS
curl -I https://ubuntu.com # 외부 HTTPS (Egress)
sudo apt update            # Egress 최종 확인, 오류 없이 끝나야 한다
nproc; free -h; df -h /    # 스펙 (W2 에서 다시 쓴다)
```

통과 기준

- VM 이 `Running` 이고 사설 IP 가 할당되었다.
- 가상 라우터 공용 IP + 포워딩 포트로 SSH 접속에 성공한다.
- `sudo apt update` 가 오류 없이 끝난다(Egress 허용 확인).
- `ip -br addr` 로 확인한 인터페이스 이름(보통 `ens3`)을 기록한다. W3 keepalived 설정에서 쓴다.

## 6. destroy 주의

```bash
terraform destroy
```

- **되돌릴 수 없다.** 인스턴스는 `expunge = true` 로 만들어져 있어 destroy 시 즉시 완전 삭제되고,
  디스크 내용은 복구할 수 없다. 검증 결과는 `verify-out/` 에 남겨 두고 destroy 한다.
- 네트워크를 지우면 그 안의 VM 사설 IP 가 모두 사라진다.
- 이 디렉터리는 W1 검증 전용이다. 각 주차 디렉터리가 **각자 자기 네트워크만** 만들고 지운다.
  다른 주차 환경을 띄워 둔 상태에서 여기서 destroy 해도 다른 주차에는 영향이 없다.
- 실습이 끝나면 반드시 destroy 한다. 공용 IP 와 컴퓨트 자원이 계속 점유된다.

## 7. 알아 둘 점

- **provider 0.5.0 버그 우회**: `cloudstack_network` 의 `source_nat_ip_id` / `source_nat_ip_address` 가
  apply 후에도 null 로 남는다. 그래서 `data "cloudstack_ipaddress"` 를 `zone_name = "DKU"` +
  `is_source_nat = "true"` 필터로 조회해 우회한다(`access.tf`). 이 방식은 pretest 에서 실제 배포로 검증되었다.
  계정에 공용 IP 가 여러 개면 필터가 모호해질 수 있으니, 그때는 `ip_address` 필터로 바꾼다.
- Egress 규칙에 ICMP 항목이 들어 있다. 계정 오퍼링에서 ICMP egress 가 허용되지 않아 오류가 나면
  `access.tf` 의 icmp `rule` 블록을 지우고 다시 apply 한다.
- W1 은 격리 네트워크를 새로 만든다. W2/W4/W5 는 기존 공용 Shared Network 를 그대로 쓴다.

## 강사 검증 환경 (참고)

| 항목 | 값 |
|---|---|
| 콘솔 | https://dku.kloud.zone |
| 계정 | hyungwook.yu (학생은 학번) |
| Domain | CE |
| API 엔드포인트 | https://dku.kloud.zone/client/api |

학생 배포용 문서에는 계정을 학번 기준으로 적어 두었다. 강사 계정은 학번 형식이 아니므로,
실습 자료의 로그인 예시와 다를 수 있다는 점만 유의한다.
