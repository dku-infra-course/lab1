# week12 · 쿠버네티스 운영 (Helm · ConfigMap/Secret · HPA)

실습 가이드: `실습_W12_K8s운영Helm.html` (CI/CD는 이론만 다루고 실습은 없다)

## 1. 목표

- Helm 차트로 앱을 설치·업그레이드·롤백한다.
- ConfigMap과 Secret을 환경변수로 주입하고, 값을 바꿔도 파드가 그대로인 이유를 확인한다.
- metrics-server와 HPA로 부하에 따라 파드 수가 늘고 줄어드는 것을 관찰한다.

## 2. 파일

| 파일 | 설명 | 실습 단계 |
|---|---|---|
| `charts/dku-demo/` | 최소 Helm 차트 (Deployment · Service, `containerPort` 값 분리) | Part B |
| `cfg/configmap.yaml` | ConfigMap `app-config` (APP_VERSION · APP_MODE) | C1 |
| `cfg/cfg-demo.yaml` | Deployment + Service(NodePort 30091) **뼈대**. `envFrom`·`env`는 직접 쓴다 | C2 |
| `hpa.yaml` | Deployment `hpa-demo`(requests 20m) + Service + HPA(CPU 50%, 1~4) | D2 |
| `ingress.yaml` | Ingress 예제(Part B의 release Service `web`으로 전달). 컨트롤러 설치는 선택 Part E | E2 |

모든 YAML과 `values.yaml`의 `<DH_USER>`는 본인 Docker Hub 아이디로 바꾼다.

```bash
mkdir -p ~/lab1 && curl -fsSL https://github.com/dku-infra-course/lab1/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C ~/lab1   # 컨트롤 노드에는 git이 없다. 11주차에 받았어도 다시 실행하면 최신으로 덮어쓴다
mkdir -p ~/k8s-w12 && cp -r ~/lab1/week12-k8s-ops/{cfg,charts,hpa.yaml,ingress.yaml} ~/k8s-w12/
cd ~/k8s-w12 && sed -i "s#<DH_USER>#$DH_USER#" hpa.yaml cfg/*.yaml charts/dku-demo/values.yaml
```

## 3. 주의

- Secret은 명령(`kubectl create secret ... --from-literal`)으로 만든다. Secret 값을 YAML로 저장소에 올리지 않는다.
- 이 클러스터에는 노드 자동 확장이 없다. 노드에 자리가 없으면 새 파드는 `Pending`에 머문다.
