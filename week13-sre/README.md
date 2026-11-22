# 13주차 실습 코드: K8s 관측과 SLO (실측 전)

네임스페이스 `monitoring`(스택), `sre-lab`(podinfo). Helm release `kps`, `backend`, `frontend`.
접속 주소는 `http://<노드IP>:<NodePort>`이며 VPN 연결이 필요하다.

| 대상 | NodePort |
|---|---|
| Grafana | 30030 |
| Prometheus | 30090 |
| Alertmanager | 30093 |
| podinfo frontend | 30980 |

## 파일
- `terraform/` 클러스터 생성(기존 클러스터가 있으면 건너뜀). `terraform.tfvars.example`을 복사해 사용
- `helm/` kps-values.yaml, podinfo-backend.yaml, podinfo-frontend.yaml
- `k8s/` slo-rules.yaml(제공 알림), my-ticket-alert.example.yaml(직접 작성)
- `load/` k6-script.js, k6-job.yaml
- `grafana/podinfo-slo-dashboard.json` 대시보드 JSON (ConfigMap 라벨 grafana_dashboard=1 로 자동 등록)
- `scripts/` fault.sh(장애 주입), mark.sh(시각 기록)

## 명령 순서
```bash
cd ~/lab1/week13-sre
# 준비(클러스터가 없을 때만)
cd terraform && cp terraform.tfvars.example terraform.tfvars   # 값 채우기
terraform init && terraform apply && cd ..

# A 스택과 앱
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f helm/kps-values.yaml --set grafana.adminPassword='<YOUR_PASSWORD>'
helm install backend podinfo/podinfo -n sre-lab --create-namespace -f helm/podinfo-backend.yaml
helm install frontend podinfo/podinfo -n sre-lab -f helm/podinfo-frontend.yaml

# B, C SLO와 알림
kubectl apply -f k8s/slo-rules.yaml
kubectl -n monitoring create configmap podinfo-slo-dashboard --from-file=grafana/podinfo-slo-dashboard.json
kubectl -n monitoring label configmap podinfo-slo-dashboard grafana_dashboard=1

# D 부하
kubectl apply -f load/k6-job.yaml && kubectl -n sre-lab logs -f job/k6-load

# E 장애 주입
./scripts/mark.sh 주입 && ./scripts/fault.sh enable
./scripts/fault.sh disable && ./scripts/mark.sh 복구
```
시크릿(tfvars, 웹훅 URL, 비밀번호)은 저장소에 올리지 않는다.
