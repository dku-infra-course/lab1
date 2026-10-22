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
| `terraform/w9-iac/` | provider · variables · data · cloud-init 템플릿, 3-Tier 평면 코드(비교용) | Part A~D |
| `terraform/w9-modules/` | web · cache · database 모듈과 호출 코드 | Part E~H, 14주차 복구 리허설 |

작업 디렉터리는 가이드대로 `~/w9-iac`, `~/iac-modules`를 쓴다.

```bash
git clone https://github.com/dku-infra-course/lab1.git ~/lab1
cd ~/lab1/terraform/w9-iac
mkdir -p ~/w9-iac && cp -r provider.tf variables.tf data.tf templates terraform.tfvars.example .gitignore ~/w9-iac/
```

main.tf·outputs.tf 는 복사하지 않고 실습 C·D 에서 직접 작성한다(완성본은 비교용으로 repo 에 있다).

모듈은 Part E1 에서 복사한다.

```bash
cp -r ~/lab1/terraform/w9-modules ~/iac-modules
```

## 4. 주의

- `terraform.tfvars`, `*.tfstate`는 커밋하지 않는다 (`.gitignore`에 있다).
- 쿼터를 지키기 위해 단계가 끝나면 `terraform destroy`로 지운다.
