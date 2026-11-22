#!/usr/bin/env bash
# 실측 전
# frontend Pod 하나에만 fault_injection을 켜고 끈다. 사용: fault.sh enable|disable|status
# 컨트롤 노드에서 실행한다. podinfo 이미지에는 curl이 없으므로 컨트롤 노드 로컬에서 kubectl port-forward(19898) 후 curl을 쓴다.
set -euo pipefail

NS="${NS:-sre-lab}"
APP="app.kubernetes.io/name=frontend-podinfo"
LPORT="${LPORT:-19898}"
ACTION="${1:-status}"
POD="${2:-}"

now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

if [ -z "$POD" ]; then
  # 지정이 없으면 첫 번째 Pod를 고른다. 이름을 인자로 주면 그 Pod를 쓴다
  POD="$(kubectl -n "$NS" get pod -l "$APP" -o jsonpath='{.items[0].metadata.name}')"
fi

kubectl -n "$NS" port-forward "pod/$POD" "${LPORT}:9898" >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
for _ in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:${LPORT}/healthz" && break
  sleep 0.5
done

case "$ACTION" in
  enable)
    curl -s -X POST "http://127.0.0.1:${LPORT}/fault_injection/enable" -o /dev/null -w "HTTP %{http_code}\n"
    echo "$(now) fault_injection ENABLE pod=$POD"
    ;;
  disable)
    curl -s -X POST "http://127.0.0.1:${LPORT}/fault_injection/disable" -o /dev/null -w "HTTP %{http_code}\n"
    echo "$(now) fault_injection DISABLE pod=$POD"
    ;;
  status)
    # 켜져 있으면 / 요청이 500을 돌려준다
    CODE="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${LPORT}/")"
    echo "$(now) pod=$POD GET / -> HTTP $CODE (500이면 주입 중)"
    ;;
  *)
    echo "사용: $0 enable|disable|status [pod이름]" >&2
    exit 1
    ;;
esac
