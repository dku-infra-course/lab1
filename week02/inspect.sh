#!/usr/bin/env bash
#
# week02 · 서버 스펙 / 리눅스 기본 / 네트워크 확인 명령 모음
#
# 실습 가이드 실습_W2_리눅스네트워크.html 의 확인 명령을 순서대로 실행한다.
# 읽기 전용 명령만 사용하며, 시스템을 변경하지 않는다.
#
# 사용법:
#   chmod +x inspect.sh
#   ./inspect.sh              # 전체 실행
#   ./inspect.sh spec         # 스펙만
#   ./inspect.sh linux        # 리눅스 기본만
#   ./inspect.sh net          # 네트워크만
#   ./inspect.sh web          # Apache 확인만 (설치되어 있어야 함)
#
# 게이트웨이·외부 통신 확인 대상은 환경 변수로 바꿀 수 있다.
#   GATEWAY=192.168.0.1 EXTERNAL_URL=https://ubuntu.com ./inspect.sh net

set -euo pipefail

GATEWAY="${GATEWAY:-}"
EXTERNAL_URL="${EXTERNAL_URL:-https://ubuntu.com}"

hr() { printf '\n=== %s ===\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" || printf '(명령이 0이 아닌 코드로 끝났다: %s)\n' "$*"; }

check_spec() {
  hr "1. 서버 스펙 확인"
  run lscpu
  run nproc
  run free -h
  run df -h
}

check_linux() {
  hr "2. 리눅스 기본 확인"
  run uname -a
  run cat /etc/os-release
  run whoami
  run id
  hr "2-1. 서비스 상태"
  run systemctl status ssh --no-pager
  printf '\n$ systemctl list-units --type=service --state=running\n'
  systemctl list-units --type=service --state=running --no-pager || true
}

check_net() {
  hr "3. 네트워크 확인"
  run ip a
  run ip route
  run ss -tlnp

  # 게이트웨이를 지정하지 않으면 기본 경로에서 자동 추출한다.
  local gw="$GATEWAY"
  if [ -z "$gw" ]; then
    gw="$(ip route | awk '/^default/ {print $3; exit}')" || true
  fi

  if [ -n "$gw" ]; then
    hr "3-1. 게이트웨이(가상 라우터)까지 닿는지"
    run ping -c 3 "$gw"
  else
    printf '\n게이트웨이를 찾지 못했다. GATEWAY 환경 변수로 지정한다.\n'
  fi

  hr "3-2. 바깥(인터넷)으로 나가는지 (Egress 확인)"
  run curl -I --max-time 10 "$EXTERNAL_URL"
}

check_web() {
  hr "4. 웹 서버(Apache) 확인"
  if ! command -v apache2 >/dev/null 2>&1; then
    printf '\napache2 가 설치되어 있지 않다. 가이드 4단계를 먼저 진행한다.\n'
    printf '  sudo apt update && sudo apt install -y apache2\n'
    return 0
  fi
  run systemctl status apache2 --no-pager
  run systemctl is-enabled apache2
  run curl -I --max-time 5 localhost
  printf '\n$ curl -s localhost | grep -i "it works"\n'
  curl -s --max-time 5 localhost | grep -i "it works" || printf '(기본 페이지를 이미 교체했다면 이 줄은 비어 있는 것이 정상)\n'
  printf '\n$ curl -s localhost\n'
  curl -s --max-time 5 localhost || true
  printf '\n$ ss -tlnp | grep :80\n'
  ss -tlnp | grep ':80' || printf '(80 포트 리스닝이 없다: apache2 기동 상태 확인)\n'
}

main() {
  local target="${1:-all}"
  printf 'week02 확인 스크립트 · 호스트: %s · 시각: %s\n' "$(hostname)" "$(date '+%F %T')"
  case "$target" in
    spec)  check_spec ;;
    linux) check_linux ;;
    net)   check_net ;;
    web)   check_web ;;
    all)   check_spec; check_linux; check_net; check_web ;;
    *)     printf '알 수 없는 인자: %s (spec | linux | net | web | all)\n' "$target"; exit 1 ;;
  esac
  hr "확인 종료"
  printf '스펙(vCPU·메모리·디스크), 인터페이스명과 사설 IP, 기본 게이트웨이, 리스닝 포트를 기록해 둔다.\n'
  printf '인터페이스명은 3주차 이후 keepalived/IPVS 설정의 {{IFACE}} 값으로 사용한다.\n'
}

main "$@"
