# week13 · 관측과 SLO

실습 가이드: `실습_W13_K8s관측과SLO.html`

## 1. 목표

- kube-prometheus-stack(Prometheus · Grafana · Alertmanager)을 Helm으로 설치한다.
- `/metrics`를 내는 앱을 배포하고 ServiceMonitor로 수집한다.
- SLO 표를 만들고 번레이트 알림 규칙 1개를 직접 작성해, 오류를 주입해 알림이 발화하는 것을 확인한다.

## 2. 파일

| 파일 | 설명 | 실습 단계 |
|---|---|---|
| `app/app.py`, `app/Dockerfile` | 지표(`/metrics`)와 `FAIL_RATE` 환경변수를 가진 앱 | Part A |
| `helm/kps-values.yaml` | 실습용 경량 설정 (Grafana NodePort 등) | Part B |
| `k8s/shop.yaml` | 앱 Deployment + Service | Part C |
| `k8s/monitoring.yaml` | ServiceMonitor + PrometheusRule(알림 규칙 예시) | Part C |

학생이 직접 쓰는 것: `my-alert.yaml`(알림 규칙 1개), SLO 표(`final/observability/slo.md`로 이어진다).

```bash
git clone https://github.com/dku-infra-course/lab1.git ~/lab1
cd ~/lab1/week13-observability
mkdir -p ~/k8s-w13 && cp -r . ~/k8s-w13 && cd ~/k8s-w13 && ls
```

## 3. 주의

- Grafana 관리자 비밀번호(`kps-values.yaml`의 `adminPassword`)는 실습용 값이다. 운영에서는 Secret으로 주입한다.
- 11주차 클러스터(control 1 + worker 1)를 그대로 쓴다. 스택이 `Pending`이면 먼저 11·12주차 잔여 자원(hpa-demo, cfg-demo, Helm release)을 지우고, 그래도 걸리면 선택 Part E를 건너뛴 뒤 담당 교수에게 알린다.
