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

## 3. 실습 VM이 없다면

이번 주 명령은 모두 10주차에 만든 실습 VM 안에서 실행한다. 10주차 VM을 지웠거나 새로 시작한다면 먼저 VM부터 다시 만든다. 이 코드는 본인 PC에서 실행하며, 9주차에 설치한 Terraform과 API 키를 쓴다.

```bash
git clone https://github.com/dku-infra-course/lab1.git ~/lab1 || git -C ~/lab1 pull
cd ~/lab1/terraform/w10-docker-vm
cp terraform.tfvars.example terraform.tfvars   # api_key, secret_key, name_prefix, shared_network_id 입력
terraform init && terraform apply
terraform output next_steps                    # 접속과 cloud-init 대기 안내
```

- VM이 `Running`이 되고 `cloud-init status --wait`가 `done`을 보인 **뒤에** 클러스터를 만든다. VM과 클러스터를 같은 시점에 요청하지 않는다.
- 새 VM에는 `docker login`이 되어 있지 않다. Part D(D4)와 Part F에서 이미지를 푸시하기 전에 `docker login -u $DH_USER`를 다시 한다.
- Docker Hub에 올려 둔 `$DH_USER/k8s-demo:1.0.0`과 내 앱 이미지는 그대로 쓴다. 다시 빌드하지 않아도 된다.
- 위 VM 단계가 끝난 뒤 이 README의 "파일" 절 명령(`export DH_USER=...` 이하)을 **VM 안에서** 실행한다.

## 4. 주의

- `kubeconfig`는 `chmod 600`으로 두고 커밋하지 않는다.
- 12주차에서 같은 클러스터를 이어 쓰므로 실습이 끝나도 클러스터를 지우지 않는다.
