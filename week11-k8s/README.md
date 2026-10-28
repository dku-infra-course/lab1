# week11 · 쿠버네티스 기본 배포

실습 가이드: `실습_W11_K8s기본배포.html`

## 1. 목표

- Solid Cloud 쿠버네티스 서비스(CKS)로 클러스터를 만들고 `kubectl`로 접속한다.
- Pod → Deployment → Service(NodePort) 순서로 배포하고, 롤링 업데이트와 롤백을 확인한다.
- 10주차에서 푸시한 이미지(`$DH_USER/k8s-demo`)와 내 앱 이미지로 교체해 본다.

## 2. 파일

| 파일 | 설명 | 실습 단계 |
|---|---|---|
| `k8s/pod.yaml` | Pod `web` (포트 이름 `http`) | C1 |
| `k8s/deployment.yaml` | Deployment (replicas 3), F4에서 이미지를 내 것으로 수정 | D1, F4 |
| `k8s/service-nodeport.yaml` | Service `demo` (NodePort 30080) | E1 |

매니페스트의 `<DH_USER>`는 본인 Docker Hub 아이디로 바꾼다.

```bash
export DH_USER=<내 Docker Hub 아이디>
git clone https://github.com/dku-infra-course/lab1.git ~/lab1 && cd ~/lab1/week11-k8s
mkdir -p ~/k8s-w11 && cp k8s/*.yaml ~/k8s-w11/ && cd ~/k8s-w11 && sed -i "s#<DH_USER>#$DH_USER#" *.yaml
```

`~/lab1` 이 이미 있다는 오류가 나면 `cd ~/lab1 && git pull` 후 `cd week11-k8s` 부터 이어서 실행한다. 결과는 `~/k8s-w11/*.yaml` 로 평평하게 놓인다.

클러스터를 코드로 만들고 싶으면 `terraform/w11-k8s/`(선택)를 쓴다. 이 환경의 CKS는 `type: LoadBalancer`의 EXTERNAL-IP가 `<pending>`으로 남으므로 NodePort를 쓴다.

## 3. 작업 위치: 컨트롤 노드

11주차부터는 별도 실습 VM 없이 클러스터의 **컨트롤 노드에 SSH로 접속해 작업한다.** 클러스터는 `terraform/w11-k8s/README.md`로 만든다(본인 PC에서 Terraform 실행). 접속 후 아래를 한 번만 준비한다.

```bash
ssh cloud@<컨트롤 노드 IP>

# kubectl: 노드에 v1.32.5가 있으나 PATH에 없어 다시 설치한다
curl -LO "https://dl.k8s.io/release/v1.32.5/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config && chmod 600 ~/.kube/config
kubectl get nodes

# docker: 이미지 빌드와 푸시에 쓴다. docker.io는 설치되지 않으므로 docker-ce를 쓴다
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker cloud && exit
```

다시 접속하면 `docker`가 `sudo` 없이 된다.

- `~/.kube/config`는 클러스터 관리자 자격 증명이다. 커밋하거나 공유하지 않는다.
- 컨트롤 노드 메모리는 4GiB다. 큰 이미지를 여러 개 빌드하지 않는다.
- Part D(D4)와 Part F에서 이미지를 푸시하기 전에 `docker login -u $DH_USER`를 한다.
- 위 준비가 끝난 뒤 이 README의 "파일" 절 명령(`export DH_USER=...` 이하)을 **컨트롤 노드 안에서** 실행한다.

## 4. 주의

- `kubeconfig`는 `chmod 600`으로 두고 커밋하지 않는다.
- 12주차에서 같은 클러스터를 이어 쓰므로 실습이 끝나도 클러스터를 지우지 않는다.
