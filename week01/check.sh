#!/usr/bin/env bash
# week01 · 전체 상태 한 번에 점검
#
# 사용법 (내 노트북에서 실행):
#   bash check.sh <공용IP> [SSH포트]
#   예) bash check.sh 10.0.1.29 2201
#
# 실습을 손으로 한 번 끝낸 뒤, 결과 대조용으로 쓴다.

PUBLIC_IP="${1:?사용법: bash check.sh <공용IP> [SSH포트]}"
SSH_PORT="${2:-2201}"

ok()   { printf "  [ OK ] %s\n" "$1"; }
fail() { printf "  [FAIL] %s\n" "$1"; }

echo "== 1. 콘솔 도달 =="
code=$(curl -s -o /dev/null -w '%{http_code}' -I "https://dku.kloud.zone" 2>/dev/null)
case "$code" in
  200|301|302) ok "콘솔 응답 $code" ;;
  *)           fail "콘솔 응답 없음 (VPN 연결과 DNS 를 확인한다)" ;;
esac

echo "== 2. 포트 도달 (포트포워딩 + 방화벽) =="
if nc -z -w 5 "$PUBLIC_IP" "$SSH_PORT" 2>/dev/null; then
  ok "$PUBLIC_IP:$SSH_PORT 열림"
else
  fail "$PUBLIC_IP:$SSH_PORT 닫힘 (8단계 포트포워딩, 9단계 방화벽 Source CIDR 확인)"
  exit 1
fi

echo "== 3. VM 안 상태 =="
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    -p "$SSH_PORT" "ubuntu@$PUBLIC_IP" 'bash -s' <<'REMOTE'
  echo "  hostname : $(hostname)"
  echo "  사설 IP  : $(hostname -I | awk '{print $1}')"
  echo "  MTU      : $(cat /sys/class/net/ens3/mtu 2>/dev/null || echo '확인 불가')"
  echo "  기본 경로: $(ip route | awk '/^default/{print $3}')"
  printf "  DNS 해석 : "; getent hosts ubuntu.com >/dev/null 2>&1 && echo "성공" || echo "실패 (Egress UDP 53 확인)"
  printf "  HTTPS    : "; curl -s -o /dev/null -m 10 -I https://ubuntu.com && echo "성공" || echo "실패 (Egress TCP 443 확인)"
  printf "  ICMP     : "; ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && echo "성공" || echo "실패 (Egress ICMP 확인)"
REMOTE

echo
echo "기대값: 기본 경로 192.168.0.1 / MTU 1450 / DNS·HTTPS·ICMP 모두 성공"
