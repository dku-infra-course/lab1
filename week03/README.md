# week03 · 서버 이중화 (Keepalived VIP Failover)

실습 가이드: `실습_W3_이중화.html`

## 1. 목표

- VRRP와 **Keepalived** 로 웹 서버 2대를 **Active/Backup(MASTER/BACKUP)** 으로 구성하고, 하나의 **가상 IP(VIP)** 로 접근한다.
- Active(web01)가 다운되면 VIP가 Backup(web02)으로 자동 이동하는 **Failover** 를 확인한다.
- Active 복구 시 우선순위에 따라 VIP가 회수되는 **Failback** 까지 관찰한다.

## 2. 사전 조건

| 항목 | 값 |
|---|---|
| web01 (MASTER · Active) | `{{WEB01_IP}}` = `192.168.0.10` · priority 110 |
| web02 (BACKUP) | `{{WEB02_IP}}` = `192.168.0.11` · priority 100 |
| 격리 네트워크 대역 | `192.168.0.0/24` |
| VIP | `{{VIP}}` = `192.168.0.100` |
| VRRP 인터페이스 | `{{IFACE}}` = `ens3` (`ip link` 로 확인) |

- 두 VM은 **같은 서브넷** 에 있어야 한다. VRRP는 동일 네트워크 안에서 동작한다.
- 두 VM이 사설 IP로 서로 `ping` 이 되고, 각각 SSH 접속이 가능해야 한다(web02용 포트포워딩 규칙 추가 필요).
- 패키지 설치를 위해 Egress(아웃바운드)가 허용되어 있어야 한다.
- VPN 연결 유지.

> DKU Solid Cloud(CloudStack 격리망)에서는 **기본 멀티캐스트 설정 그대로 정상 동작** 하는 것으로 사전 검증되었다. 멀티캐스트가 막힌 다른 환경이라면 `keepalived-unicast-web01.conf.example` 을 참고해 유니캐스트로 바꾼다.

## 3. 파일

| 파일 | 설명 |
|---|---|
| `keepalived-web01.conf` | web01(MASTER) 용 `/etc/keepalived/keepalived.conf` 원본 |
| `keepalived-web02.conf` | web02(BACKUP) 용 원본. web01과 다른 값은 `state` · `priority` 두 개뿐이다 |
| `keepalived-unicast-web01.conf.example` | 멀티캐스트가 막힌 환경용 유니캐스트 참고본 (DKU 환경에서는 불필요) |
| `install-keepalived.sh` | Apache + Keepalived 설치, 설정 배치, 서비스 기동 |
| `verify-vip.sh` | VIP 보유 여부 · VIP 응답 · VRRP 로그 확인 (읽기 전용) |

두 노드가 **반드시 같아야** 하는 값: `virtual_router_id`(51), `auth_pass`(1234), `virtual_ipaddress`(VIP).
두 노드가 **달라야** 하는 값: `state`, `priority`.

## 4. 실행 순서

### 4-1. 인터페이스 이름 확인 (양쪽 노드)

```bash
ip link
```

`ens3` 가 아니면 아래 명령의 `IFACE` 값을 실제 이름으로 바꾼다.

### 4-2. 저장소 받기 (양쪽 노드)

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/dku-infra-course/lab1.git
cd lab1/week03
chmod +x *.sh
```

### 4-3. 설치 (역할별로 한 번씩)

web01 에서:

```bash
IFACE=ens3 VIP=192.168.0.100 ./install-keepalived.sh web01
```

web02 에서:

```bash
IFACE=ens3 VIP=192.168.0.100 ./install-keepalived.sh web02
```

스크립트는 `/etc/keepalived/keepalived.conf` 와 `/var/www/html/index.html` 을 덮어쓰기 전에 **확인 프롬프트** 를 띄우고, 기존 파일을 `.bak.<타임스탬프>` 로 백업한다.

### 4-4. 스크립트를 쓰지 않고 직접 하는 경우

```bash
sudo apt update
sudo apt install -y apache2 keepalived

# web01
echo "<h1>Active Server</h1>" | sudo tee /var/www/html/index.html
# web02
echo "<h1>Backup Server</h1>" | sudo tee /var/www/html/index.html

# 설정 배치 (자리표시자 치환)
sed -e 's/{{IFACE}}/ens3/g' -e 's/{{VIP}}/192.168.0.100/g' \
    keepalived-web01.conf | sudo tee /etc/keepalived/keepalived.conf

sudo systemctl restart keepalived
sudo systemctl enable keepalived
sudo systemctl enable --now apache2
```

## 5. 검증 방법

```bash
./verify-vip.sh web01     # web01 에서
./verify-vip.sh web02     # web02 에서
```

통과 기준

| 확인 | 명령 | 기대 결과 |
|---|---|---|
| 서비스 상태 | `systemctl status keepalived` | `active (running)` |
| VIP 위치 | `ip addr show ens3` | web01 에만 `192.168.0.100` 이 보인다 |
| VIP 응답 | `curl 192.168.0.100` | `<h1>Active Server</h1>` |
| Failover | web01 에서 `sudo systemctl stop keepalived.service` 후 `curl 192.168.0.100` | `<h1>Backup Server</h1>` 로 바뀐다 |
| Failover 로그 | web02 에서 `journalctl -u keepalived -f` | `Entering MASTER STATE` |
| Failback | web01 에서 `sudo systemctl start keepalived.service` 후 `curl 192.168.0.100` | 다시 `<h1>Active Server</h1>` |

> Apache만 중단(`sudo systemctl stop apache2`)해서는 기본 설정의 Keepalived가 VIP를 옮기지 않는다. Keepalived는 노드의 VRRP 상태만 감시한다. 웹 프로세스 장애까지 감지하려면 `vrrp_script` + `track_script` 가 필요하다.

## 6. 정리 (rollback)

이번 주 확인이 끝났으면 VM 2대와 격리 네트워크를 정리(Destroy)한다. 4주차는 이 환경을 이어 쓰지 않고 새로 만든다.
(예외: 4주차 IPVS 심화(B3)를 이 환경에 이어서 하기로 했다면 VM은 남겨 둔다. 강사 안내를 따른다.)

Keepalived 설정만 되돌릴 때:

```bash
# 서비스 중지 및 자동 시작 해제
sudo systemctl disable --now keepalived

# VIP 가 인터페이스에서 내려갔는지 확인
ip addr show ens3 | grep 192.168.0.100 || echo "VIP 제거 확인"

# 설정 원복 (install 스크립트가 남긴 백업 사용)
ls -1 /etc/keepalived/keepalived.conf.bak.* 2>/dev/null
# sudo cp /etc/keepalived/keepalived.conf.bak.<타임스탬프> /etc/keepalived/keepalived.conf

# 페이지 원복
ls -1 /var/www/html/index.html.bak.* 2>/dev/null
# sudo cp /var/www/html/index.html.bak.<타임스탬프> /var/www/html/index.html

# 패키지 제거 (선택)
sudo apt remove -y keepalived
```

Keepalived를 중지했는데도 VIP가 남아 있으면 `sudo ip addr del 192.168.0.100/32 dev ens3` 로 직접 내린다.
