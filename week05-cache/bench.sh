#!/usr/bin/env bash
#
# week05 · 캐시 효과 측정 (응답 시간 비교)
#
# 실습 가이드 실습_W5_캐시.html Part 7 의 time curl 측정을 스크립트로 옮긴 것이다.
# curl 의 time_total 을 여러 번 측정해 평균을 낸다. 읽기 전용(GET)만 수행한다.
#
# 사용법:
#   chmod +x bench.sh
#   ./bench.sh                 # 기본값으로 전체 측정
#   ./bench.sh 5               # 각 항목을 5회씩 측정
#
# 환경 변수:
#   WEBSERVER_IP=192.168.0.10  백엔드(Flask) 서버 IP
#   CACHE_IP=192.168.0.20      캐시 서버(Nginx/Squid) IP
#
# 실행 위치에 따라 무엇을 측정할 수 있는지 다르다.
#   백엔드 서버 VM : 원본 / Redis 캐시
#   캐시 서버 VM   : Nginx 캐시 / Squid 캐시 / 이중 캐싱
# 두 VM 에서 각각 실행한 뒤 결과를 합쳐 표로 정리한다.

set -euo pipefail

RUNS="${1:-3}"
WEBSERVER_IP="${WEBSERVER_IP:-192.168.0.10}"
CACHE_IP="${CACHE_IP:-192.168.0.20}"

# 자리표시자를 그대로 둔 채 실행한 경우를 걸러 준다.
case "$WEBSERVER_IP$CACHE_IP" in
  *'{{'*)
    echo "자리표시자를 치환하지 않았다. 아래처럼 환경 변수로 넘긴다." >&2
    echo "  WEBSERVER_IP=192.168.0.10 CACHE_IP=192.168.0.20 ./bench.sh" >&2
    exit 1 ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "curl 이 필요하다: sudo apt install -y curl" >&2
  exit 1
fi

hr() { printf '\n--- %s ---\n' "$1"; }

# 대상 URL 을 RUNS 회 호출하고 각 회차 시간과 평균을 출력한다.
# 인자: <라벨> <curl 추가 인자...>
measure() {
  local label="$1"; shift
  local i t total="0" ok=0
  hr "$label"
  for ((i=1; i<=RUNS; i++)); do
    if t="$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$@" 2>/dev/null)"; then
      printf '  %d회: %ss\n' "$i" "$t"
      total="$(awk -v a="$total" -v b="$t" 'BEGIN{printf "%.4f", a+b}')"
      ok=$((ok+1))
    else
      printf '  %d회: 실패 (도달 불가 또는 타임아웃)\n' "$i"
    fi
  done
  if [ "$ok" -gt 0 ]; then
    printf '  평균: %ss (%d회 성공)\n' "$(awk -v s="$total" -v n="$ok" 'BEGIN{printf "%.4f", s/n}')" "$ok"
  else
    printf '  평균: 측정 불가\n'
  fi
}

# 캐시를 비운 상태의 첫 요청(MISS)과 이어지는 요청(HIT)을 나눠 보여 준다.
measure_miss_hit() {
  local label="$1" url="$2"
  hr "$label"
  local first second
  first="$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$url" 2>/dev/null || echo "실패")"
  printf '  1회 (MISS 예상): %ss\n' "$first"
  second="$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$url" 2>/dev/null || echo "실패")"
  printf '  2회 (HIT 예상) : %ss\n' "$second"
}

cat <<INFO
============================================================
 week05 캐시 효과 측정
============================================================
 호스트        : $(hostname)
 백엔드 서버   : $WEBSERVER_IP
 캐시 서버     : $CACHE_IP
 반복 횟수     : $RUNS
============================================================
INFO

echo
echo "[백엔드 서버 VM 에서 의미 있는 항목]"
measure "1) 캐시 미적용 (원본, 매 요청 약 2초)" "http://localhost:5000/api/products"
measure_miss_hit "2) Redis 애플리케이션 캐시 (TTL 10초)" "http://localhost:5000/api/products-cached"

echo
echo "[캐시 서버 VM 에서 의미 있는 항목]"
measure_miss_hit "3) Nginx 리버스 프록시 캐시" "http://localhost/api/products"
measure "4) Squid 포워드 프록시 캐시" --proxy "http://localhost:3128" "http://$WEBSERVER_IP:5000/api/products"
measure_miss_hit "5) 이중 캐싱 (Nginx 10초 + Redis 30초)" "http://localhost/api/products-dual"

cat <<'GUIDE'

=== 캐시 상태 헤더 확인 ===
  curl -sI http://localhost/api/products | grep -i x-cache-status
  curl -sI "http://localhost/api/products?nocache=1" | grep -i x-cache-status   # 항상 MISS
  sudo cat /var/log/squid/access.log | tail -5                                   # TCP_MISS / TCP_HIT

=== 캐시를 비우고 다시 측정하려면 ===
  sudo rm -rf /var/cache/nginx/api_cache/*      # Nginx 캐시
  redis-cli DEL products:all                    # Redis 캐시 (FLUSHALL 은 쓰지 않는다)

=== 통과 기준 ===
  - 캐시 미적용은 반복해도 계속 약 2초다.
  - Redis / Nginx / Squid 모두 첫 요청은 약 2초, 두 번째 요청은 수십 ms 이하로 떨어진다.
  - 절대 수치는 VM 사양·네트워크에 따라 다르다. 상대적 차이(2초 → 수 ms)를 확인하는 것이 목적이다.
GUIDE
