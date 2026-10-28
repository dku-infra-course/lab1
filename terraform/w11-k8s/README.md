# w11-k8s · 쿠버네티스 클러스터 (Terraform)

## 1. 목표

11주차부터 쿠버네티스 클러스터를 Terraform으로 만든다. 별도 실습 VM은 만들지 않고, **컨트롤 노드에 SSH로 접속해 그 안에서 `kubectl`, `helm`, `docker`를 쓴다.** 본인 PC에는 Terraform과 SSH 클라이언트만 있으면 된다.

- 만들어지는 것: SSH 키페어 1개, CKS 클러스터 1개(Medium, control 1 + worker 1, 노드 2대)
- 계정 한도는 동시 Medium 3대(6 vCPU / 12GiB)다. 클러스터가 4 vCPU / 8GiB를 쓰고 2 vCPU / 4GiB가 남는다. 노드 수는 늘리지 않는다.
- 노드 두 개는 같은 오퍼링이다(이 provider에서는 노드별로 다른 크기를 줄 수 없다).

## 2. 파일

| 파일 | 내용 |
|---|---|
| `main.tf` `variables.tf` `provider.tf` `outputs.tf` | SSH 키페어와 CKS 클러스터 (`cloudstack/cloudstack` ~> 0.5.0) |
| `terraform.tfvars.example` | 입력값 견본. `terraform.tfvars`로 복사해 채운다 |
| `verify.sh` | 읽기 전용 점검 스크립트. 컨트롤 노드에서 실행한다 |

## 3. 실행 (본인 PC)

1. SSH 키가 없으면 만든다. 이 키로 노드에 접속한다.

   ```bash
   ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
   ```

2. 입력 파일을 만든다. `api_key`, `secret_key`, `name_prefix`(학번), `shared_network_id`를 채운다. Shared Network ID는 콘솔 Networks 상세 화면에서 복사한다.

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. 클러스터를 만든다. 정상이면 약 3~4분 안에 끝난다.

   ```bash
   terraform init
   terraform apply
   ```

4. 콘솔 > 컴퓨트 > 인스턴스에서 `k8s-<학번>-control`로 시작하는 VM의 IP를 확인하고 접속한다(VPN 연결 필요).

   ```bash
   ssh cloud@<컨트롤 노드 IP>
   ```

   사용자 이름은 `cloud`이고 비밀번호 없이 `sudo`가 된다. 이후 도구 설치와 `kubectl` 연결은 `week11-k8s/README.md`를 따른다.

5. 끝나면 정리한다. 키페어도 함께 지워진다.

   ```bash
   terraform destroy
   ```

   클러스터를 12주차 이후에도 쓰면 11주차에서는 지우지 않는다.

## 4. 주의

- 계정당 클러스터는 하나다. 콘솔로 만든 클러스터가 있으면 먼저 지운다.
- **`shared_network_id`는 반드시 Shared Network로 넣는다.** 비우면 격리망이 새로 만들어지고 클러스터가 `Starting`에서 멈춘다. 이 상태에서는 삭제도 거부되므로 10분 넘게 `Starting`이면 삭제하지 말고 담당 교수에게 알린다. 변수에 빈 값 검사가 들어 있어 비워 두면 apply 전에 막힌다.
- 노드 접속은 `ssh_public_key_path`의 키로만 된다(기본 `~/.ssh/id_ed25519.pub`). 이 키를 지정하지 않으면 노드에 접속할 수 없다.
- `worker_size`는 1로 둔다. 2로 올리면 control 1 + worker 2 = Medium 3대(6 vCPU / 12GiB)가 되어 한도를 다 쓴다.
- `terraform.tfvars`, `*.tfstate`, 개인키(`~/.ssh/id_ed25519`)는 시크릿이다. 저장소에 커밋하지 않는다.
- NodePort(30000-32767)는 VPN을 연결한 상태에서 어느 노드의 IP로든 접속한다. 포트포워딩은 필요 없다. 노드 IP는 `kubectl get nodes -o wide`로 본다.
- `type: LoadBalancer` Service의 EXTERNAL-IP는 `<pending>`으로 남는다. 이 환경에는 로드밸런서를 만들어 주는 구성 요소가 없으므로 NodePort를 쓴다.
- `verify.sh`는 읽기 전용이다. 컨트롤 노드에서 `./verify.sh`로 실행하고, 결과는 `verify-out/`에 저장되며 커밋 대상이 아니다.
