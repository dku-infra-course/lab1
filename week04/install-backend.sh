#!/usr/bin/env bash
#
# week04 · 백엔드 웹서버(Apache) 구성
#
# 실습 가이드 실습_W4_로드밸런싱.html 의 "공통 준비 · 백엔드 웹서버 2대 구성" 을
# 스크립트로 옮긴 것이다. 백엔드는 Apache, 앞단 로드밸런서는 Nginx 다.
#
# 사용법:
#   chmod +x install-backend.sh
#   ./install-backend.sh web01                    # 페이지: Web Server 01
#   ./install-backend.sh web02                    # 페이지: Administrator Page
#   ./install-backend.sh web02 "Web Server 02"    # 페이지 문구 직접 지정 (B2 단계)
#
# 이 스크립트는 /var/www/html/index.html 을 덮어쓴다.
# 기존 파일은 .bak.<타임스탬프> 로 백업하고, 실행 전 확인 프롬프트가 나온다.

set -euo pipefail

ROLE="${1:-}"
CUSTOM_LABEL="${2:-}"

usage() {
  cat <<'USAGE'
사용법: ./install-backend.sh <web01|web02> ["페이지 문구"]

  web01  페이지 기본값 "Web Server 01"
  web02  페이지 기본값 "Administrator Page"
         L4 Stream 분산 확인 단계(B2)에서는 두 번째 인자로 "Web Server 02" 를 준다.
USAGE
}

case "$ROLE" in
  web01) LABEL="${CUSTOM_LABEL:-Web Server 01}" ;;
  web02) LABEL="${CUSTOM_LABEL:-Administrator Page}" ;;
  *)     usage; exit 1 ;;
esac

cat <<INFO

============================================================
 week04 백엔드 웹서버 구성
============================================================
 대상 호스트   : $(hostname)
 역할          : $ROLE
 페이지 문구   : $LABEL

 아래 작업을 수행한다.
   1) apt update && apt install apache2
   2) /var/www/html/index.html 덮어쓰기 (기존 파일은 .bak 백업)
   3) apache2 기동 및 자동 시작 활성화
============================================================

INFO

read -r -p "위 내용으로 진행한다. 계속하려면 yes 를 입력한다: " ANSWER
if [ "$ANSWER" != "yes" ]; then
  echo "취소했다. 변경 사항 없음."
  exit 0
fi

echo
echo "[1/3] Apache 설치"
sudo apt update
sudo apt install -y apache2

echo
echo "[2/3] 구분용 페이지 작성"
if [ -f /var/www/html/index.html ]; then
  sudo cp -n /var/www/html/index.html "/var/www/html/index.html.bak.$(date +%Y%m%d%H%M%S)"
fi
printf '<h1>%s</h1>\n' "$LABEL" | sudo tee /var/www/html/index.html >/dev/null
cat /var/www/html/index.html

echo
echo "[3/3] 서비스 기동"
sudo systemctl enable --now apache2
sudo systemctl reload apache2
sudo systemctl status apache2 --no-pager || true

echo
echo "로컬 확인:"
curl -s --max-time 5 localhost || true

cat <<DONE

완료했다. 두 백엔드 모두 구성한 뒤, 로드밸런서 VM 에서 다음을 진행한다.

  sudo apt install -y nginx
  sed -e 's/{{WEB01_IP}}/<web01 실제 사설 IP>/g' -e 's/{{WEB02_IP}}/<web02 실제 사설 IP>/g' \\
      nginx-lb.conf | sudo tee /etc/nginx/sites-available/http-lb
  sudo ln -s /etc/nginx/sites-available/http-lb /etc/nginx/sites-enabled/
  sudo unlink /etc/nginx/sites-enabled/default
  sudo nginx -t && sudo systemctl reload nginx
DONE
