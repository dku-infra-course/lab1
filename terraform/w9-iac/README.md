# W9 Terraform 실습 (3-Tier)

`실습_W9_Terraform기초.html` 의 완성 코드다. 학생은 단계별로 직접 작성하고, 막히면 이 코드와 비교한다.

| 파일 | 역할 |
|---|---|
| provider.tf | cloudstack provider (~> 0.5.0), 자격증명은 변수로 |
| variables.tf | 입력 변수. 기본값은 실습 환경 값 |
| data.tf | zone·template·service offering 조회 |
| main.tf | web(count) · cache · db 인스턴스 |
| outputs.tf | IP 출력 |
| templates/cloud-init.tftpl | 역할별 패키지 설치 (apache2 / redis-server / mariadb-server) |

```bash
cp terraform.tfvars.example terraform.tfvars   # 키·학번·Shared Network ID 입력
terraform init && terraform plan && terraform apply
./verify.sh
terraform destroy
```

합계: web Small x2 + cache Small + db Medium = 5 vCPU / 10GB RAM.

**실습과의 관계**: 실습의 Part C~D는 이 코드의 web 부분(VM 1대, count, output)을 단계별로 쓴다. 이 폴더의 cache·db를 포함한 평면 코드는 "같은 블록이 세 번 반복된다"를 보여 주는 비교용이다. 3계층 배포는 Part E에서 모듈 코드(`terraform/w9-modules`, 수강생 디렉터리 `~/iac-modules`)로 한다.

