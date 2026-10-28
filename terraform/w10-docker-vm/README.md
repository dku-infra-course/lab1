# w10-docker-vm · Docker 실습 VM

## 1. 목표

10주차 실습 Part A의 VM 준비 방법이다(2026-10-22부터 Terraform으로 통일). Ubuntu 24.04 VM 1대(Medium, 2 vCPU / 4GB)를 만들고 cloud-init으로 `docker.io`, `docker-compose-v2`, `git`, `curl`을 설치하고 `ubuntu` 사용자를 `docker` 그룹에 넣는다. 가이드 A1에서 이 코드를 실행하고, A2에서 접속해 확인한다.

쿼터: 학생 1인 동시 Medium 3대(6 vCPU / 12GB) 이내이며, 이 VM은 11~14주차에도 kubectl·docker 작업용으로 재사용하므로 실습 중간에 지우지 않아도 된다. 지웠다면 11주차 시작 전에 같은 코드로 다시 만든다(`week11-k8s/README.md` 참고).

## 2. 파일

| 파일 | 역할 |
|---|---|
| provider.tf · variables.tf · data.tf | 9주차와 같은 구성 (cloudstack provider ~> 0.5.0) |
| main.tf | VM 1대 (Medium, 루트 디스크 20GB, `expunge = true`) |
| templates/cloud-init.tftpl | docker.io, docker-compose-v2, docker 그룹 |
| outputs.tf | VM 사설 IP, 접속·대기 안내(`next_steps`) |
| terraform.tfvars.example | 입력값 예시 (복사해 `terraform.tfvars`로 사용) |

## 3. 실행

```bash
cp terraform.tfvars.example terraform.tfvars   # 키·학번·Shared Network ID 입력
terraform init && terraform apply
terraform output next_steps                    # 접속과 대기 안내
ssh ubuntu@$(terraform output -raw docker_vm_ip)   # VPN 연결 필요
cloud-init status --wait                       # VM 안에서. done 이 나올 때까지 기다린다
exit                                           # 다시 로그인 (또는 newgrp docker)
ssh ubuntu@$(terraform output -raw docker_vm_ip)
docker run --rm hello-world
terraform destroy                              # 11~14주차 작업이 모두 끝난 뒤에 지운다
```

## 4. 주의

- docker 그룹: cloud-init이 끝나기 전에 들어온 ssh 세션에는 그룹이 반영되지 않는다. `cloud-init status --wait`가 `done`을 보인 뒤 다시 로그인하거나 `newgrp docker`를 실행한다. 그렇지 않으면 `docker: permission denied`가 난다.
- apt 미러: 이 코드는 apt 미러 주소를 바꾸지 않는다. `apt update`가 실패하면 강사에게 문의한다.
- 디스크: 루트 디스크는 20GB다. 30으로 지정해도 20GB로 만들어져 다음 `terraform plan`이 교체(-/+)를 요구하므로 기본값을 20으로 둔다. 파일시스템은 약 19GB이고, 10주차 전 과정을 마친 뒤 사용량은 약 4.6GB(Trivy DB 캐시 볼륨 약 1.6GB 포함)였다. 이미지를 많이 쌓으면 `docker system df`로 확인하고 `docker system prune`으로 정리한다.
- Trivy는 설치하지 않는다. 실습 D에서 고정 버전 컨테이너로 실행한다.
- `terraform.tfvars`, `*.tfstate`에 키와 비밀번호가 남는다. 저장소에 올리지 않는다(`.gitignore` 대상).
- 이 코드는 Shared Network를 만들지 않으므로 destroy해도 네트워크는 남는다. VM은 `expunge = true`라 즉시 완전 삭제된다.
