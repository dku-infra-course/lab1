# 13주차 실습 코드: K8s 관측과 SLO

네임스페이스 `monitoring`(스택), `sre-lab`(podinfo). Helm release `kps`, `backend`, `frontend`.
접속 주소는 `http://<노드IP>:<NodePort>`이며 VPN 연결이 필요하다.

## 작업 위치
11주차에 만든 클러스터를 이어 쓴다. **모든 명령(`kubectl`, `helm`, `./scripts/*.sh`)은 컨트롤 노드에 SSH(`ssh cloud@<컨트롤 노드 IP>`)로 접속해 그 안에서 실행한다.** 브라우저(Grafana, Prometheus, Alertmanager, frontend)만 본인 PC에서 VPN으로 `<노드IP>:<NodePort>`에 접속한다.
- 클러스터가 없으면 `terraform/w11-k8s/README.md`로 먼저 만든다(본인 PC에서 Terraform 실행). 이 폴더에는 Terraform 코드가 없다.
- `kubectl get nodes`나 `helm version`이 `command not found`이면 컨트롤 노드에서 아래 도구 준비를 한 번 실행한다(11주차 도구 준비, 12주차 A1과 같은 명령).
```bash
curl -LO "https://dl.k8s.io/release/v1.32.5/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config && chmod 600 ~/.kube/config
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh && DESIRED_VERSION=v3.22.0 ./get_helm.sh
kubectl get nodes && helm version
```
- 컨트롤 노드에는 `git`이 없으므로 저장소는 tar로 받는다. 이미 `~/lab1`이 있어도 같은 명령을 다시 실행하면 덮어쓴다(직접 고친 `helm/podinfo-backend.yaml`도 원래 값으로 돌아간다).
```bash
mkdir -p ~/lab1 && curl -fsSL https://github.com/dku-infra-course/lab1/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C ~/lab1 && cd ~/lab1/week13-sre
```

| 대상 | NodePort |
|---|---|
| Grafana | 30030 |
| Prometheus | 30090 |
| Alertmanager | 30093 |
| podinfo frontend | 30980 |

## 파일
- `helm/` kps-values.yaml, podinfo-backend.yaml, podinfo-frontend.yaml
- `k8s/` slo-rules.yaml(제공 알림), my-ticket-alert.example.yaml(직접 작성)
- `load/` k6-script.js, k6-job.yaml
- `grafana/podinfo-slo-dashboard.json` 대시보드 JSON (ConfigMap 라벨 grafana_dashboard=1 로 자동 등록)
- `scripts/` fault.sh(장애 주입), mark.sh(시각 기록)

## 명령 순서
```bash
# 컨트롤 노드에서 (ssh cloud@<컨트롤 노드 IP>)
cd ~/lab1/week13-sre
kubectl get nodes

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
시크릿(웹훅 URL, 비밀번호)은 저장소에 올리지 않는다.
