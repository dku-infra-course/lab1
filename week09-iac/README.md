# week09 · IaC (Terraform + Ansible 이론, Terraform 실습)

실습 가이드: `실습_W9_Terraform기초.html`

## 1. 목표

- 콘솔 클릭으로 만든 VM을 Terraform 코드로 선언하고, `init → plan → apply`로 만든다.
- State와 멱등성을 확인하고, 반복되는 3-Tier 코드를 **모듈**로 나눈다.
- `destroy → apply`로 같은 환경이 다시 만들어지는 시간을 기록한다 (14주차 복구 실습에서 쓴다).

## 2. 사전 조건

- Terraform 설치 (`terraform/README.md`), VPN 연결, Solid Cloud API Key
- Shared Network ID (콘솔 [네트워크] 상세)

## 3. 파일

이 주차의 코드는 `terraform/` 아래에 있다.

| 폴더 | 용도 | 실습 단계 |
|---|---|---|
| `terraform/w9-iac/` | 완성본(비교용). 막혔을 때 내 파일과 비교한다 | Part A~D |
| `terraform/w9-modules/` | web · cache · database 모듈과 호출 코드 | Part E~H |

9주차 Part A~D는 이 repo를 받지 않고, 빈 작업 디렉터리 `~/w9-iac`에서 `provider.tf`, `variables.tf`, `data.tf`, `terraform.tfvars`, `templates/cloud-init.tftpl`, `main.tf`, `outputs.tf`를 가이드를 보며 직접 만든다. `terraform/w9-iac/`의 파일은 같은 내용의 완성본이므로 틀린 곳을 찾을 때만 열어 비교한다.

repo는 Part E1에서 처음 받는다.

```bash
git clone https://github.com/dku-infra-course/lab1.git ~/lab1
cp -r ~/lab1/terraform/w9-modules ~/iac-modules
```

`~/lab1`이 이미 있다는 오류가 나면 `cd ~/lab1 && git pull`로 최신으로 맞춘 뒤 `cp`부터 다시 실행한다.

## 4. 주의

- `terraform.tfvars`, `*.tfstate`는 커밋하지 않는다 (`.gitignore`에 있다).
- 쿼터를 지키기 위해 단계가 끝나면 `terraform destroy`로 지운다.
