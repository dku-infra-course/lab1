#!/usr/bin/env bash
# W9 검증(읽기 전용). terraform apply 가 끝난 디렉터리에서 실행한다.
#   ./verify.sh            terraform 상태와 출력만 확인
#   SSH_CHECK=1 ./verify.sh  VPN 연결 상태에서 각 VM 의 역할 파일과 서비스까지 확인 (ssh 키 필요)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
OUT=verify-out; mkdir -p "$OUT"; LOG=$OUT/w9-$(date +%Y%m%d-%H%M%S).txt
{
  echo "== terraform state list"; terraform state list
  echo "== terraform output"; terraform output
  echo "== plan (No changes 이어야 멱등, exit=0)"
  terraform plan -detailed-exitcode -no-color > "$OUT/plan.tmp" 2>&1; rc=$?
  tail -5 "$OUT/plan.tmp"; rm -f "$OUT/plan.tmp"
  echo "exit=$rc  (0=변경 없음, 2=변경 있음, 1=오류)"
} 2>&1 | tee "$LOG"
if [ "${SSH_CHECK:-0}" = "1" ]; then
  # shellcheck disable=SC2046  # IP 목록을 공백 기준으로 나누려는 의도
  # cache_ip 는 cache_count=0 이면 null 이므로 -json 으로 읽고 null 은 건너뛴다
  cache_ip=$(terraform output -json cache_ip 2>/dev/null | tr -d '"')
  [ "$cache_ip" = "null" ] && cache_ip=""
  for ip in $(terraform output -json web_ips | tr -d '[]" ' | tr ',' ' ') $cache_ip $(terraform output -raw db_ip); do
    echo "== $ip" | tee -a "$LOG"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 "ubuntu@$ip" 'cat /etc/dku-lab-role; systemctl is-active apache2 redis-server mariadb 2>/dev/null' 2>&1 | tee -a "$LOG"
  done
fi
