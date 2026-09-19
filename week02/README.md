# week02 · 서버 스펙 · 리눅스 기본 · 네트워크 확인

실습 가이드: `실습_W2_리눅스네트워크.html`

## 1. 목표

- SSH로 접속한 VM에서 **스펙(vCPU · 메모리 · 디스크)** 을 확인한다.
- 리눅스 기본 명령과 **systemd 서비스 상태** 확인 방법을 익힌다.
- **인터페이스명 · 사설 IP · 기본 게이트웨이 · 리스닝 포트** 를 확인하고, 게이트웨이와 외부 통신이 되는지 검증한다.
- Apache를 설치해 웹 서버가 뜨는 것을 확인한다.

## 2. 사전 조건

- 1주차에서 만든 VM이 `Running` 이고, 포트포워딩(`2201` → `22`)으로 SSH 접속이 된다.
- Egress(아웃바운드)가 허용되어 있다. `sudo apt update` 가 되어야 한다.
- VPN 연결 유지.

## 3. 실행 순서

로컬 터미널에서 VM에 접속한다.

```bash
ssh -p 2201 ubuntu@{{PUBLIC_IP}}
```

VM 안에서 이 저장소를 받아 스크립트를 실행한다.

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs/week02-linux-network
chmod +x checks.sh
./checks.sh
```

부분 실행도 가능하다.

```bash
./checks.sh spec     # lscpu, nproc, free -h, df -h
./checks.sh linux    # uname, os-release, whoami, id, systemctl
./checks.sh net      # ip a, ip route, ss -tlnp, ping, curl
./checks.sh web      # Apache 상태 (설치 후)
```

게이트웨이나 외부 확인 주소를 바꿀 때:

```bash
GATEWAY=192.168.0.1 EXTERNAL_URL=https://ubuntu.com ./checks.sh net
```

`checks.sh` 는 **읽기 전용 확인 명령만** 실행한다. 아래 설치·변경 작업은 가이드를 보며 직접 수행한다.

```bash
# 패키지 설치 확인
sudo apt update
apt list --upgradable
sudo apt install -y tree

# Apache 설치와 페이지 교체
sudo apt install -y apache2
echo "<h1>DKU Infra W2 - $(hostname)</h1>" | sudo tee /var/www/html/index.html
sudo systemctl enable apache2
```

외부(내 PC)에서 웹 서버까지 닿는지 확인하려면, 콘솔에서 `8001` → `80` 포트포워딩과 방화벽 개방을 추가한 뒤 로컬 터미널에서 확인한다.

```bash
curl http://{{PUBLIC_IP}}:8001
```

## 4. 검증 방법

| 확인 항목 | 명령 | 통과 기준 |
|---|---|---|
| vCPU 수 | `nproc` | 콘솔의 컴퓨트 오퍼링과 값이 일치 |
| 메모리 | `free -h` | 오퍼링 값과 근사 (일부는 커널이 점유) |
| 디스크 | `df -h` | `/` 의 Size가 템플릿 디스크 크기와 근사 |
| 인터페이스명 | `ip a` | `ens3` 등. **이 값을 기록해 3주차 `{{IFACE}}` 로 사용** |
| 기본 게이트웨이 | `ip route` | `default via <게이트웨이> dev <인터페이스>` 존재 |
| 게이트웨이 도달 | `ping -c 3 <게이트웨이>` | 3 packets transmitted, 3 received |
| 외부 통신 | `curl -I https://ubuntu.com` | `HTTP/... 200` 또는 `301` |
| SSH 리스닝 | `ss -tlnp` | `0.0.0.0:22` LISTEN |
| Apache 리스닝 | `ss -tlnp \| grep :80` | `:80` LISTEN |
| Apache 자동 시작 | `systemctl is-enabled apache2` | `enabled` |

## 5. 정리 (rollback)

이번 주 확인이 끝났으면 VM과 격리 네트워크를 정리(Destroy)한다. 3주차는 이 환경을 이어 쓰지 않고 새로 만든다.
