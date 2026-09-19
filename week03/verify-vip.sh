#!/usr/bin/env bash
#
# week03 · VIP 상태와 Failover 검증
#
# 읽기 전용 확인만 수행한다. 서비스를 중단하거나 설정을 바꾸지 않는다.
#
# 사용법:
#   chmod +x verify-vip.sh
#   ./verify-vip.sh              # 현재 노드 상태 + VIP 응답 확인
#   ./verify-vip.sh web01        # 기대 역할을 지정하면 일치 여부까지 판정
#   ./verify-vip.sh web02
#
# 환경 변수:
#   IFACE=ens3 VIP=192.168.0.100 ./verify-vip.sh

set -euo pipefail

EXPECT_ROLE="${1:-}"
IFACE="${IFACE:-ens3}"
VIP="${VIP:-192.168.0.100}"

hr() { printf '\n=== %s ===\n' "$1"; }
FAIL=0

hr "0. 대상"
printf '호스트   : %s\n' "$(hostname)"
printf '인터페이스: %s\n' "$IFACE"
printf 'VIP      : %s\n' "$VIP"
[ -n "$EXPECT_ROLE" ] && printf '기대 역할: %s\n' "$EXPECT_ROLE"

hr "1. keepalived 서비스 상태"
if systemctl is-active --quiet keepalived; then
  echo "active (running)"
else
  echo "keepalived 가 실행 중이 아니다."
  FAIL=1
fi
systemctl is-enabled keepalived || true

hr "2. 인터페이스에 VIP 가 올라와 있는가"
if ip addr show "$IFACE" | grep -q "$VIP"; then
  HAS_VIP=yes
  echo "이 노드가 VIP 를 보유하고 있다 (MASTER)."
  ip addr show "$IFACE" | grep "$VIP"
else
  HAS_VIP=no
  echo "이 노드에는 VIP 가 없다 (BACKUP 이거나 아직 협상 중)."
fi

hr "3. VIP 응답 확인"
if curl -s --max-time 5 "http://$VIP" ; then
  echo
else
  echo "VIP 로 HTTP 응답을 받지 못했다."
  FAIL=1
fi

hr "4. 최근 VRRP 로그 (마지막 20줄)"
if [ -r /var/log/syslog ]; then
  sudo grep -i vrrp /var/log/syslog | tail -20 || echo "(VRRP 로그 없음)"
else
  # Ubuntu 24.04 등 journald 기본 환경
  sudo journalctl -u keepalived -n 20 --no-pager || echo "(journalctl 조회 실패)"
fi

hr "5. 판정"
if [ -n "$EXPECT_ROLE" ]; then
  case "$EXPECT_ROLE" in
    web01)
      if [ "$HAS_VIP" = "yes" ]; then
        echo "web01(MASTER, priority 110) 이 VIP 를 보유: 정상"
      else
        echo "web01 인데 VIP 가 없다. web02 가 MASTER 를 잡고 있는지, priority 값이 뒤바뀌지 않았는지 확인한다."
        FAIL=1
      fi ;;
    web02)
      if [ "$HAS_VIP" = "no" ]; then
        echo "web02(BACKUP, priority 100) 에 VIP 가 없음: 정상"
      else
        echo "web02 가 VIP 를 보유하고 있다. web01 이 다운되었거나(Failover 진행 중) 양쪽 모두 MASTER 인 split-brain 상태일 수 있다."
        echo "web01 에서도 이 스크립트를 실행해 VIP 중복 여부를 확인한다."
      fi ;;
  esac
fi

printf '\nFailover 검증 순서 (수동)\n'
printf '  1) web01, web02 각각에서 로그를 따라가며 둔다\n'
printf '       sudo journalctl -u keepalived -f\n'
printf '       (rsyslog 를 따로 설치해 /var/log/syslog 가 있으면) sudo tail -f /var/log/syslog | grep -i vrrp\n'
printf '  2) web01 에서 장애 주입:  sudo systemctl stop keepalived.service\n'
printf '  3) web02 로그에 "Entering MASTER STATE" 가 나오는지 확인\n'
printf '  4) curl http://%s 응답이 Backup Server 로 바뀌는지 확인\n' "$VIP"
printf '  5) 복구:  web01 에서 sudo systemctl start keepalived.service\n'
printf '  6) 우선순위 110 > 100 에 따라 VIP 가 web01 로 회수되는지 확인 (Failback)\n'

exit "$FAIL"
