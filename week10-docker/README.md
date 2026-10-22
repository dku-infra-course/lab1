# week10 · Docker 컨테이너

실습 가이드: `실습_W10_Docker컨테이너.html`

## 1. 목표

- 샘플 앱을 빌드해 고정 태그로 Docker Hub에 푸시한다 (11~14주차가 이어서 쓴다).
- AI로 만든 내 앱을 컨테이너화하고, 멀티스테이지·비루트·`.dockerignore`·HEALTHCHECK를 검토한다.
- Trivy로 이미지를 스캔하고, Compose로 앱 + Redis를 실행한다.

## 2. 파일

| 폴더 / 파일 | 설명 | 실습 단계 |
|---|---|---|
| `sample-app/` | `k8s-demo` 샘플 (포트 8000, 응답에 호스트명·버전). 앱과 포트는 바꾸지 않는다 | Part B |
| `example-app/Dockerfile.single` | 단일 스테이지 비교용 | C5 |
| `example-app/Dockerfile` | 멀티스테이지 · 비루트 · HEALTHCHECK 비교용 정답 | C6 |
| `example-app/compose.yaml` | 앱 + Redis, 네트워크·볼륨·헬스체크 | Part E |
| `example-app/app.py`, `requirements.txt` | Flask + Redis 예제 앱 | Part C, E |

```bash
git clone https://github.com/dku-infra-course/lab1.git ~/lab1
cd ~/lab1/week10-docker
mkdir -p ~/k8s-demo && cp sample-app/* ~/k8s-demo/
```

`example-app` 파일은 실습 C5·E1 에서 repo 경로(`~/lab1/week10-docker/example-app`)에서 직접 복사한다.

Docker VM을 코드로 만들고 싶으면 `terraform/w10-docker-vm/`(선택)을 쓴다.

## 3. 주의

- Trivy는 `0.69.3`으로 고정하고 호스트의 `docker.sock`은 마운트하지 않는다 (실습 D의 공급망 사고 설명 참고).
- 토큰·비밀번호를 이미지나 저장소에 넣지 않는다.
