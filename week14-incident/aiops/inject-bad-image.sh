#!/usr/bin/env bash
# 실측 전
# D3용 장애 주입: frontend를 존재하지 않는 이미지 태그로 배포한다 (ImagePullBackOff).
# 관리자 kubeconfig로 사람이 실행한다. 에이전트에게 실행시키지 않는다.
# 복구: helm rollback frontend -n sre-lab  (또는 kubectl -n sre-lab rollout undo deploy/frontend-podinfo)
set -euo pipefail

NS="${NS:-sre-lab}"
BAD_TAG="${BAD_TAG:-6.99.99-does-not-exist}"

echo "$(date -u +%FT%TZ) 주입 시작: image.tag=$BAD_TAG"
# Helm 4는 server-side apply라서, 앞서 kubectl rollout undo 를 한 Deployment는 image 필드를 kubectl이 소유해 충돌(conflict)이 난다.
# --force-conflicts 가 있는 helm(4 이상)에서만 붙인다. Helm 3에는 이 문제와 플래그가 없다.
FC=(); if helm upgrade --help 2>/dev/null | grep -q -- '--force-conflicts'; then FC=(--force-conflicts); fi
helm upgrade frontend podinfo/podinfo -n "$NS" --reuse-values --set image.tag="$BAD_TAG" ${FC[@]+"${FC[@]}"}
echo "$(date -u +%FT%TZ) 주입 완료. 새 Pod가 ImagePullBackOff가 된다. 기존 Pod 일부는 남아 있어 부분 장애로 보인다."
kubectl -n "$NS" get pods -l app.kubernetes.io/name=frontend-podinfo
