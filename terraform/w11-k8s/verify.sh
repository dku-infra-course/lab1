#!/usr/bin/env bash
#
# W11/W12 K8s 점검 스크립트
#
# kubeconfig 로 클러스터 상태, NodePort 접근, Helm release 를 읽기 전용으로 확인한다.
# kubeconfig 내용은 출력하지 않는다. 결과는 verify-out/ 에 저장되며 .gitignore 대상이다.
#
# 사용법
#   KUBECONFIG=~/.kube/config ./verify.sh
#   KUBECONFIG=~/.kube/config NODEPORT=30080 ./verify.sh     # NodePort 번호를 바꿀 때
#
# ---------------------------------------------------------------------------
# 이 스크립트는 읽기 전용이다. 리소스를 만들거나 지우지 않는다.
# ---------------------------------------------------------------------------

WEEK="w11"
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

: "${KUBECONFIG:?KUBECONFIG 환경변수에 kubeconfig 파일 경로를 지정한다}"
NODEPORT="${NODEPORT:-30080}"

OUT_DIR="$SCRIPT_DIR/verify-out"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/${WEEK}-$(date +%Y%m%d-%H%M%S).txt"

log()     { printf '%s\n' "$*" | tee -a "$LOG"; }
section() { printf '\n================================================================\n== %s\n================================================================\n' "$*" | tee -a "$LOG"; }

section "1. 노드 상태"
kubectl get nodes -o wide 2>&1 | tee -a "$LOG"

section "2. 전체 파드 (Running/Completed 아닌 것만)"
kubectl get pods -A --no-headers 2>&1 | awk '$4!="Running" && $4!="Completed"' | tee -a "$LOG"
log "(위에 아무것도 없으면 정상)"

section "3. 서비스 / 워크로드"
kubectl get deploy,svc,pods 2>&1 | tee -a "$LOG"

section "4. NodePort ${NODEPORT} 접근 (모든 노드 IP)"
for ip in $(kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'); do
  if body="$(curl -s -m 5 "http://$ip:$NODEPORT" 2>&1)"; then
    log "$ip:$NODEPORT -> $body"
  else
    log "$ip:$NODEPORT -> 접근 실패 (VPN 연결과 NodePort 번호를 확인한다)"
  fi
done

section "5. LoadBalancer 서비스 EXTERNAL-IP (pending 이 정상: cloud-controller 없음)"
kubectl get svc -A 2>&1 | awk 'NR==1 || $3=="LoadBalancer"' | tee -a "$LOG"

section "6. Helm release"
if command -v helm >/dev/null 2>&1; then
  helm list -A 2>&1 | tee -a "$LOG"
  kubectl get secret -A -l owner=helm --no-headers 2>&1 | tee -a "$LOG"
else
  log "helm 이 설치되어 있지 않다"
fi

section "결과 파일"
log "$LOG"
