# W3 실습 환경 (Terraform) - 서버 이중화 (Keepalived VIP Failover)

3주차 실습 가이드 `실습_W3_이중화.html` 검증용 환경이다.
**격리 네트워크(Isolated Network)를 새로 만들고** web01/web02 를 같은 서브넷에 올린다.
VRRP 는 같은 서브넷 안에서만 동작하므로 Shared Network 가 아니라 격리 네트워크를 쓴다.

**학습 대상은 자동화하지 않는다.** 기본값(`preinstall_packages = false`, `preinstall_keepalived_config = false`)은
패키지조차 설치하지 않은 순정 Ubuntu다. 학생이 콘솔로 직접 만드는 VM과 조건을 맞추기 위한 것이고,
녹화·직접 실습 목적으로는 이 기본값을 그대로 쓴다.

- `preinstall_packages = true`: apache2·keepalived·curl 을 설치만 한다(keepalived 서비스는 꺼진 채로 둔다).
- `preinstall_keepalived_config = true`: 패키지 설치까지 포함해서 keepalived.conf 배치와 서비스 기동까지
  마친 완성 상태로 만든다. 강사가 failover 만 빠르게 재확인하고 싶을 때 쓴다.

## 1. 만들어지는 것

| 리소스 | 값 |
|---|---|
| 격리 네트워크 | `tf-<name_prefix>-net`, CIDR `192.168.0.0/24` |
| web01 (MASTER) | `192.168.0.10`, `state MASTER`, `priority 110`, 페이지 `Active Server` |
| web02 (BACKUP) | `192.168.0.11`, `state BACKUP`, `priority 100`, 페이지 `Backup Server` |
| VIP | `192.168.0.100` |
| 접속 | 가상 라우터 공용 IP 의 `2201` -> web01 `22`, `2202` -> web02 `22` |
| cloud-init | Apache 설치 + 페이지 생성, keepalived **설치만** (정지·비활성화 상태) |

두 노드가 반드시 같아야 하는 값: `virtual_router_id`(51), `auth_pass`(1234), `virtual_ipaddress`(VIP).
달라야 하는 값: `state`, `priority`.

## 2. 전제

- 로컬에 Terraform 1.0 이상, **VPN 연결**.
- CloudStack API Key / Secret Key. **발급 위치: 우측 상단 프로필 > 사용자 상세 > API 키 생성.**
- 컴퓨트 오퍼링 이름은 확인됨: `Small`(1core/2GB) · `Medium`(2core/4GB) · `Large`(4core/8GB) · `XLarge`(8core/16GB) · `Custom`. 방화벽 Source CIDR 로 쓸 **VPN 대역은 `10.8.0.0/24`로 확인됨.**
- 자격증명은 `terraform.tfvars`(gitignore 대상) 또는 `TF_VAR_api_key` / `TF_VAR_secret_key`.

## 3. 실행

```bash
cp terraform.tfvars.example terraform.tfvars   # api_key / secret_key 입력
terraform init
terraform plan
terraform apply
terraform output
```

keepalived 설정까지 한 번에 올리려면:

```bash
terraform apply -var preinstall_keepalived_config=true
```

## 4. 출력값으로 접속

```bash
terraform output ssh_web01        # ssh -p 2201 ubuntu@<가상라우터공용IP>
terraform output ssh_web02        # ssh -p 2202 ubuntu@<가상라우터공용IP>
terraform output vip              # 192.168.0.100

$(terraform output -raw ssh_web01)
```

## 5. 검증용 명령 모음

```bash
./verify.sh                # 읽기 전용 확인
./verify.sh --failover     # keepalived 정지로 failover 주입 후 자동 복구
SSHPASS=ubuntu ./verify.sh
```

결과는 `verify-out/w3-<타임스탬프>.txt` 에 저장된다.

기본 상태(`preinstall_packages = false`, `preinstall_keepalived_config = false`, 패키지도 안 깔린 순정 Ubuntu)에서
손으로 하는 순서(`sudo apt install -y apache2 keepalived curl` 부터 시작한다):

```bash
# 0) 인터페이스 이름 확인 (양쪽 노드)
ip link

# 1) web01 에 MASTER 설정 배치
sudo tee /etc/keepalived/keepalived.conf > /dev/null <<'CONF'
vrrp_instance VI_1 {
    state MASTER
    interface ens3
    virtual_router_id 51
    priority 110
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    virtual_ipaddress {
        192.168.0.100
    }
}
CONF

# 2) web02 는 state BACKUP, priority 100 만 다르게 하여 같은 방식으로 배치

# 3) 양쪽에서 기동
sudo systemctl enable --now keepalived
```

설정 원본은 `files/keepalived-web01.conf` / `files/keepalived-web02.conf` 에도 그대로 들어 있다
(`labs/week03-ha-keepalived` 와 동일한 파일이다).

확인 명령:

```bash
# 서비스
systemctl status keepalived --no-pager
systemctl is-active keepalived

# VIP 위치 (web01 에만 192.168.0.100 이 보여야 한다)
ip a
ip addr show ens3

# VIP 응답
curl 192.168.0.100          # <h1>Active Server</h1>

# VRRP 로그
sudo journalctl -u keepalived -n 30 --no-pager
sudo journalctl -u keepalived -f          # 실시간

# Failover
#   web01 에서
sudo systemctl stop keepalived.service
#   그 뒤 어디서든
curl 192.168.0.100          # <h1>Backup Server</h1> 로 바뀐다
#   web02 로그에 Entering MASTER STATE
sudo journalctl -u keepalived -n 20 --no-pager

# Failback
#   web01 에서
sudo systemctl start keepalived.service
curl 192.168.0.100          # 다시 <h1>Active Server</h1>
```

통과 기준

| 확인 | 기대 결과 |
|---|---|
| 서비스 상태 | 양쪽 `active (running)` |
| VIP 위치 | web01 에만 `192.168.0.100` |
| VIP 응답 | `<h1>Active Server</h1>` |
| Failover | web01 keepalived 정지 후 `<h1>Backup Server</h1>` |
| Failover 로그 | web02 에 `Entering MASTER STATE` |
| Failback | web01 재기동 후 다시 `<h1>Active Server</h1>` |

Apache 만 중단(`systemctl stop apache2`)해서는 VIP 가 옮겨가지 않는다.
keepalived 는 노드의 VRRP 상태만 감시한다. 웹 프로세스 장애까지 감지하려면
`vrrp_script` + `track_script` 가 필요하다.

## 6. 멀티캐스트와 유니캐스트

DKU Solid Cloud 격리망에서는 **기본 멀티캐스트 설정 그대로 정상 동작**하는 것이
`terraform-w3-ha-pretest` 로 사전 검증되었다. VRRP 광고(224.0.0.18, IP protocol 112)는
같은 서브넷 안에서 주고받는 트래픽이라 Egress 방화벽 규칙과 무관하다.

양쪽이 모두 MASTER 가 되는 split-brain 이 보이면 멀티캐스트가 막힌 것이다. 그때는:

```bash
terraform apply -var preinstall_keepalived_config=true -var keepalived_use_unicast=true
```

`files/keepalived-unicast-web01.conf` / `files/keepalived-unicast-web02.conf` 가 쓰이며
`unicast_src_ip` 와 `unicast_peer` 가 서로 반대로 들어간다. 두 노드 모두 고정 IP 로
배포되므로 failover 중에도 값이 바뀌지 않는다.

## 7. destroy 주의

```bash
terraform destroy
```

- **되돌릴 수 없다.** `expunge = true` 이므로 VM 과 디스크가 즉시 완전 삭제된다.
- 격리 네트워크를 지우면 그 안의 사설 IP 가 모두 사라진다.
- 검증 결과(`verify-out/`)를 먼저 확보한다.
- `./verify.sh --failover` 가 중간에 끊겼다면 web01 의 keepalived 가 정지 상태로 남을 수 있다.
  destroy 하지 않고 계속 쓸 계획이면 `sudo systemctl start keepalived` 로 복구한다.
- 실습이 끝나면 반드시 destroy 한다. 공용 IP 와 컴퓨트 자원이 계속 점유된다.

## 8. 알아 둘 점

- **provider 0.5.0 버그 우회**: `cloudstack_network` 의 `source_nat_ip_*` 가 null 로 오므로
  `data "cloudstack_ipaddress"` 를 `zone_name` + `is_source_nat` 필터로 조회해 우회한다(`access.tf`).
- cloud-init 은 파일 내용을 `encoding: b64` 로 넣는다. 들여쓰기나 특수문자로 YAML 이 깨지는 것을 막기 위한 것이다.
- Egress 규칙의 ICMP 항목이 계정 오퍼링에서 거부되면 해당 `rule` 블록을 지우고 다시 apply 한다.

## 강사 검증 환경 (참고)

| 항목 | 값 |
|---|---|
| 콘솔 | https://dku.kloud.zone |
| 계정 | hyungwook.yu (학생은 학번) |
| Domain | CE |
| API 엔드포인트 | https://dku.kloud.zone/client/api |

학생 배포용 문서에는 계정을 학번 기준으로 적어 두었다. 강사 계정은 학번 형식이 아니므로,
실습 자료의 로그인 예시와 다를 수 있다는 점만 유의한다.
