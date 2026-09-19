#!/usr/bin/env bash
# week02 · 웹서버 기동 스크립트
#
# 사용법 (VM 안에서 실행):
#   bash web-setup.sh
#
# 실습 문서 Part D 를 손으로 한 번 끝낸 뒤 쓴다.
# 이 스크립트는 두 번째 VM 을 같은 상태로 맞출 때 편하다.
set -e

echo "== apache2 설치 =="
sudo apt update
sudo apt install -y apache2

echo "== 이 서버를 구분할 수 있는 페이지 작성 =="
echo "<h1>$(hostname)</h1>" | sudo tee /var/www/html/index.html

echo "== 기동과 자동시작 =="
sudo systemctl enable --now apache2

echo "== 확인 =="
systemctl is-enabled apache2
systemctl is-active apache2
sudo ss -tlnp | grep ':80' || echo "80 번 리스닝이 보이지 않는다"
curl -s localhost

echo
echo "내 노트북 브라우저에서 확인할 주소: http://$(hostname -I | awk '{print $1}')"
