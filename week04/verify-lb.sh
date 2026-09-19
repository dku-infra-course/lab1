#!/usr/bin/env bash
#
# week04 · 로드밸런싱 분산 · 페일오버 · 프록시 투명성 검증
#
# 읽기 전용 확인만 수행한다. 서비스를 중단하거나 설정을 바꾸지 않는다.
# (백엔드 중지는 사용자가 직접 수행한다. 아래 안내 참고)
#
# 사용법:
#   chmod +x verify-lb.sh
#   ./verify-lb.sh                       # 기본값으로 전체 확인
#   ./verify-lb.sh 20                    # 20회 반복 요청
#
# 환경 변수 (본 실습 3대는 Shared Network DHCP 라 고정 기본값이 없다. 셋 다 필수):
#   LB_IP=<lb 실제 사설 IP>       로드밸런서(Nginx) VM IP
#   WEB01_IP=<web01 실제 사설 IP> 백엔드 1
#   WEB02_IP=<web02 실제 사설 IP> 백엔드 2
#   VIP=192.168.0.100             IPVS / HAProxy 가상 IP (심화 B3, 별도 격리 네트워크에서만 사용)
#   STREAM_PORT=8080              Nginx stream(L4) 리스닝 포트

set -euo pipefail

COUNT="${1:-10}"
LB_IP="${LB_IP:-}"
WEB01_IP="${WEB01_IP:-}"
WEB02_IP="${WEB02_IP:-}"
VIP="${VIP:-192.168.0.100}"
STREAM_PORT="${STREAM_PORT:-8080}"

case "$LB_IP$WEB01_IP$WEB02_IP" in
  *'{{'*|'')
    echo "LB_IP·WEB01_IP·WEB02_IP를 환경 변수로 넘겨야 한다(고정 기본값 없음, Shared Network DHCP)." >&2
    echo "  LB_IP=10.0.x.x WEB01_IP=10.0.x.x WEB02_IP=10.0.x.x ./verify-lb.sh" >&2
    exit 1 ;;
esac

hr() { printf '\n=== %s ===\n' "$1"; }

# 대상 주소로 COUNT 회 요청하고 응답별 횟수를 집계한다.
distribution() {
  local url="$1" label="$2" i body
  hr "$label ($url, ${COUNT}회)"
  if ! curl -s --max-time 5 -o /dev/null "$url"; then
    echo "응답을 받지 못했다. 이 대상은 아직 구성되지 않았거나 도달하지 못한다."
    return 0
  fi
  : > /tmp/lb-verify-$$.txt
  for ((i=1; i<=COUNT; i++)); do
    body="$(curl -s --max-time 5 "$url" | tr -d '\r' | tr -s ' \n' ' ' | sed 's/^ *//;s/ *$//')"
    printf '%3d  %s\n' "$i" "$body"
    printf '%s\n' "$body" >> /tmp/lb-verify-$$.txt
  done
  echo "--- 응답별 집계 ---"
  sort /tmp/lb-verify-$$.txt | uniq -c | sort -rn
  rm -f /tmp/lb-verify-$$.txt
}

hr "0. 대상"
printf 'LB        : %s\n' "$LB_IP"
printf '백엔드 1  : %s\n' "$WEB01_IP"
printf '백엔드 2  : %s\n' "$WEB02_IP"
printf 'VIP       : %s (IPVS/HAProxy 심화 단계)\n' "$VIP"
printf '반복 횟수 : %s\n' "$COUNT"

hr "1. 백엔드 직접 응답"
printf '$ curl http://%s/\n' "$WEB01_IP"; curl -s --max-time 5 "http://$WEB01_IP/" || echo "(응답 없음)"
printf '$ curl http://%s/\n' "$WEB02_IP"; curl -s --max-time 5 "http://$WEB02_IP/" || echo "(응답 없음)"

distribution "http://$LB_IP" "2. Nginx HTTP upstream (L7) 분산"
distribution "http://$LB_IP:$STREAM_PORT" "3. Nginx Stream (L4) 분산"
distribution "http://$VIP" "4. IPVS / HAProxy 분산 (심화)"

hr "5. 리버스 프록시 투명성"
echo "백엔드 직접 응답과 프록시 경유 응답이 같은지 비교한다."
DIRECT="$(curl -s --max-time 5 "http://$WEB02_IP/" || true)"
VIA="$(curl -s --max-time 5 "http://$LB_IP/" || true)"
printf '직접  : %s\n' "$DIRECT"
printf '경유  : %s\n' "$VIA"
echo "백엔드 접근 로그에 실제 클라이언트 IP가 X-Real-IP 로 남는지는 백엔드에서 확인한다."
echo "  tail -f /var/log/apache2/access.log"

cat <<GUIDE

=== 6. 페일오버 확인 (직접 수행) ===
  1) 백엔드 한 대에서 Apache 를 중지한다.
       sudo systemctl stop apache2
  2) 이 스크립트를 다시 실행한다.
       ./verify-lb.sh $COUNT
  3) 기대 결과
       Nginx / HAProxy : 장애 서버를 배제하고 살아 있는 서버로만 전달한다.
                         클라이언트는 오류 없이 응답을 계속 받는다.
       IPVS            : 헬스체크가 없어 장애 서버로도 계속 분산되어 일부 요청이 실패한다(한계 확인).
  4) 복구
       sudo systemctl start apache2

=== 통과 기준 ===
  - weight 3:1 설정에서 web01 응답이 web02 보다 약 3배 자주 관측된다.
  - 백엔드 1대를 중지해도 Nginx 경유 요청이 오류 없이 처리된다.
  - 프록시 경유 응답과 백엔드 직접 응답의 본문이 동일하다.
GUIDE
