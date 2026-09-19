#!/usr/bin/env bash
#
# week03 · Apache + Keepalived 설치 및 설정 배치
#
# 실습 가이드 실습_W3_이중화.html 의 1~5단계를 스크립트로 옮긴 것이다.
#
# 사용법:
#   chmod +x install-keepalived.sh
#   ./install-keepalived.sh web01      # MASTER (priority 110)
#   ./install-keepalived.sh web02      # BACKUP (priority 100)
#
# 환경 변수로 값을 바꿀 수 있다.
#   IFACE=ens3 VIP=192.168.0.100 ./install-keepalived.sh web01
#
# 이 스크립트는 아래 파일을 덮어쓴다.
#   /etc/keepalived/keepalived.conf   (기존 파일은 .bak 으로 백업)
#   /var/www/html/index.html          (기존 파일은 .bak 으로 백업)
# 실행 전 확인 프롬프트가 나온다.

set -euo pipefail

ROLE="${1:-}"
IFACE="${IFACE:-ens3}"
VIP="${VIP:-192.168.0.100}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
사용법: ./install-keepalived.sh <web01|web02>

  web01  MASTER 로 설정 (state MASTER, priority 110, 페이지 "Active Server")
  web02  BACKUP 로 설정 (state BACKUP, priority 100, 페이지 "Backup Server")

환경 변수:
  IFACE   VRRP 인터페이스 이름 (기본 ens3, `ip link` 로 확인)
  VIP     가상 IP (기본 192.168.0.100)
USAGE
}

case "$ROLE" in
  web01) SRC_CONF="$SCRIPT_DIR/keepalived-web01.conf"; PAGE="<h1>Active Server</h1>"; STATE="MASTER"; PRIO="110" ;;
  web02) SRC_CONF="$SCRIPT_DIR/keepalived-web02.conf"; PAGE="<h1>Backup Server</h1>"; STATE="BACKUP"; PRIO="100" ;;
  *)     usage; exit 1 ;;
esac

if [ ! -f "$SRC_CONF" ]; then
  echo "설정 원본을 찾을 수 없다: $SRC_CONF" >&2
  exit 1
fi

# 인터페이스가 실제로 존재하는지 확인한다.
if ! ip link show "$IFACE" >/dev/null 2>&1; then
  echo "인터페이스 '$IFACE' 를 찾을 수 없다. 아래 목록에서 실제 이름을 확인한 뒤" >&2
  echo "IFACE=<이름> ./install-keepalived.sh $ROLE 형태로 다시 실행한다." >&2
  ip -o link show | awk -F': ' '{print "  - " $2}' >&2
  exit 1
fi

cat <<INFO

============================================================
 week03 Keepalived 설치 · 설정
============================================================
 역할            : $ROLE ($STATE, priority $PRIO)
 인터페이스      : $IFACE
 VIP             : $VIP
 웹 페이지 내용  : $PAGE
 설정 원본       : $SRC_CONF

 아래 작업을 수행한다.
   1) apt update && apt install apache2 keepalived
   2) /var/www/html/index.html 덮어쓰기      (기존 파일은 .bak 백업)
   3) /etc/keepalived/keepalived.conf 덮어쓰기 (기존 파일은 .bak 백업)
   4) keepalived / apache2 재시작 및 자동 시작 활성화
============================================================

INFO

read -r -p "위 내용으로 진행한다. 계속하려면 yes 를 입력한다: " ANSWER
if [ "$ANSWER" != "yes" ]; then
  echo "취소했다. 변경 사항 없음."
  exit 0
fi

echo
echo "[1/4] 패키지 설치"
sudo apt update
sudo apt install -y apache2 keepalived

echo
echo "[2/4] 서버 구분용 페이지 작성"
if [ -f /var/www/html/index.html ]; then
  sudo cp -n /var/www/html/index.html "/var/www/html/index.html.bak.$(date +%Y%m%d%H%M%S)"
fi
echo "$PAGE" | sudo tee /var/www/html/index.html >/dev/null
cat /var/www/html/index.html

echo
echo "[3/4] Keepalived 설정 배치"
if [ -f /etc/keepalived/keepalived.conf ]; then
  sudo cp -n /etc/keepalived/keepalived.conf "/etc/keepalived/keepalived.conf.bak.$(date +%Y%m%d%H%M%S)"
fi
TMP_CONF="$(mktemp)"
sed -e "s|{{IFACE}}|$IFACE|g" -e "s|{{VIP}}|$VIP|g" "$SRC_CONF" > "$TMP_CONF"
sudo install -m 0644 "$TMP_CONF" /etc/keepalived/keepalived.conf
rm -f "$TMP_CONF"
echo "--- /etc/keepalived/keepalived.conf ---"
sudo cat /etc/keepalived/keepalived.conf

echo
echo "[4/4] 서비스 재시작 및 자동 시작 활성화"
sudo systemctl restart keepalived
sudo systemctl enable keepalived
sudo systemctl enable --now apache2
sudo systemctl status keepalived --no-pager || true

cat <<DONE

완료했다. 다음으로 검증 스크립트를 실행한다.

  ./verify-vip.sh $ROLE

두 노드 모두에 설치한 뒤에 검증하는 것이 맞다. web01 에만 설치한 상태라면
web01 이 MASTER 로 VIP 를 잡고 있는 것이 정상이다.
DONE
