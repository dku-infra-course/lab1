# W11 쿠버네티스 클러스터 (Terraform, 선택)

## 1. 목표

11주차 가이드에서 콘솔로 만드는 클러스터를 코드로 만들어 보는 선택 경로다. 정본은 콘솔 절차이고, 이 폴더는 같은 결과를 Terraform 으로 재현해 보고 싶은 사람이 쓴다.

- 만들어지는 것: CKS 클러스터 1개, Medium control 1 + worker 1 (노드 2대)
- 계정 한도가 동시 Medium 3대(6 vCPU / 12GiB)라서 실습 VM(10주차) 1대와 합쳐 3대가 된다. 노드 수는 늘리지 않는다.

## 2. 파일

| 파일 | 내용 |
|---|---|
| `main.tf` `variables.tf` `provider.tf` `outputs.tf` | CKS 클러스터 (`cloudstack/cloudstack` ~> 0.5.0) |
| `terraform.tfvars.example` | 입력값 견본. `terraform.tfvars` 로 복사해 채운다 |
| `verify.sh` | 읽기 전용 점검 스크립트 (노드, 파드, NodePort, Helm) |

## 3. 실행

1. 입력 파일을 만든다. `api_key`, `secret_key`, `name_prefix`(학번), `shared_network_id` 를 채운다. Shared Network ID 는 콘솔 Networks 상세 화면에서 복사한다.

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. 클러스터를 만든다. 정상이면 약 3~4분 안에 끝난다(실측 4분 8초).

   ```bash
   terraform init
   terraform apply
   ```

3. 콘솔 > 쿠버네티스 > 내 클러스터에서 kubeconfig 를 내려받아 실습 VM 의 `~/.kube/config` 에 붙여 넣는다. 이 provider 버전에는 kubeconfig 를 읽어 오는 기능이 없어 콘솔에서 받는다.

   ```bash
   mkdir -p ~/.kube
   vim ~/.kube/config            # 내려받은 내용을 붙여 넣는다
   chmod 600 ~/.kube/config
   kubectl get nodes        # 노드 2대가 Ready
   ```

4. 11주차 실습(Pod · Deployment · Service)은 가이드 C 이후를 그대로 따른다.

5. 끝나면 정리한다.

   ```bash
   terraform destroy
   ```

   클러스터를 12주차에도 쓰면 11주차에서는 지우지 않는다.

## 4. 주의

- 계정당 클러스터는 하나다. 콘솔로 만든 클러스터가 있으면 먼저 지운다.
- **`shared_network_id` 는 반드시 Shared Network 로 넣는다.** 비우면 격리망이 새로 만들어지고 클러스터가 `Starting` 에서 멈춘다. 이 상태에서는 삭제도 거부되므로 10분 넘게 `Starting` 이면 삭제하지 말고 담당 교수에게 알린다. 변수에 빈 값 검사가 들어 있어 비워 두면 apply 전에 막힌다.
- `terraform.tfvars`, `*.tfstate`, kubeconfig 는 시크릿이다. 저장소에 커밋하지 않는다(`.gitignore` 에 들어 있다).
- NodePort(30000-32767)는 VPN 을 연결한 상태에서 어느 노드의 IP 로든 접속한다. 포트포워딩은 필요 없다. 노드 IP 는 `kubectl get nodes -o wide` 로 본다.
- `type: LoadBalancer` Service 의 EXTERNAL-IP 는 `<pending>` 으로 남는다. 이 환경에는 로드밸런서를 만들어 주는 구성 요소가 없으므로 NodePort 를 쓴다.
- `worker_size` 는 1 로 둔다. 2 로 올리면 실습 VM 1 + control 1 + worker 2 = Medium 4대(8 vCPU / 16GiB)가 되어 학생 한도를 넘는다.
- `verify.sh` 는 읽기 전용이다. `KUBECONFIG=~/.kube/config ./verify.sh` 로 실행하고, 결과는 `verify-out/` 에 저장되며 커밋 대상이 아니다.
