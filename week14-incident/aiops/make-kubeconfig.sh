#!/usr/bin/env bash
# 실측 전
# ServiceAccount 토큰으로 전용 kubeconfig를 만든다. 토큰은 화면에 출력하지 않는다.
# 사용: ./make-kubeconfig.sh [SA 이름, 기본 ai-reader] [유효 시간, 기본 2h]
#   ai-reader  -> ~/.kube/ai-reader.config
#   ai-operator -> ~/.kube/ai-operator.config
set -euo pipefail

SA="${1:-ai-reader}"
DURATION="${2:-2h}"
NS="${NS:-sre-lab}"
OUT="$HOME/.kube/${SA}.config"

mkdir -p "$HOME/.kube"
umask 077

# 현재 컨텍스트(관리자)에서 서버 주소와 CA를 읽는다
SERVER="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')"
CA_DATA="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"
CA_FILE="$(mktemp)"
trap 'rm -f "$CA_FILE"' EXIT
if [ -n "$CA_DATA" ]; then
  # macOS 구버전은 -D, 그 외는 -d
  printf '%s' "$CA_DATA" | { base64 -d 2>/dev/null || base64 -D; } > "$CA_FILE"
else
  cp "$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority}')" "$CA_FILE"
fi

# 토큰은 변수에만 두고 출력하지 않는다
TOKEN="$(kubectl -n "$NS" create token "$SA" --duration="$DURATION")"

rm -f "$OUT"
kubectl config --kubeconfig="$OUT" set-cluster sre-lab --server="$SERVER" \
  --certificate-authority="$CA_FILE" --embed-certs=true >/dev/null
kubectl config --kubeconfig="$OUT" set-credentials "$SA" --token="$TOKEN" >/dev/null
kubectl config --kubeconfig="$OUT" set-context "$SA" --cluster=sre-lab --user="$SA" --namespace="$NS" >/dev/null
kubectl config --kubeconfig="$OUT" use-context "$SA" >/dev/null
chmod 600 "$OUT"
unset TOKEN

echo "생성: $OUT (유효 $DURATION, 권한 600). 내용은 열어 보지 않는다."
echo "확인: KUBECONFIG=$OUT kubectl auth can-i get pods -n $NS    # yes"
echo "확인: KUBECONFIG=$OUT kubectl auth can-i delete pods -n $NS  # no"
echo "확인: KUBECONFIG=$OUT kubectl auth can-i get secrets -n $NS  # no"
