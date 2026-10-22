# w9-modules · Terraform 모듈화 (3-Tier)

`실습_W9_Terraform기초.html` Part E~H 에서 쓰는 완성 코드다(14주차 복구 리허설에도 쓴다). `terraform/w9-iac` 의 평면 코드를 `modules/web · cache · database` 로 나눴다.

```
.
├── main.tf        모듈 호출만 한다
├── data.tf        조회(zone·template·offering)
├── variables.tf   입력 (web_count 로 웹 계층을 늘리고 cache_count 로 캐시를 켜고 끈다)
├── outputs.tf     IP 와 ansible_inventory
├── templates/cloud-init.tftpl
└── modules/{web,cache,database}/{main,variables,outputs}.tf
```

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform plan && terraform apply
terraform output -raw ansible_inventory > inventory.ini
terraform destroy
```

`cache_count`(기본 1, 0 또는 1만 허용)로 캐시 서버를 켜고 끈다. 기본값(web 2 + cache 1 + db 1)은 그대로이고, 14주차 복구 리허설처럼 한도가 빠듯할 때는 `-var web_count=0 -var cache_count=0` 으로 DB 만 만든다. `-replace` 와 `destroy` 에도 같은 `-var` 를 준다. 빠뜨리면 기본값의 web 2 + cache 1 이 함께 만들어진다.

```bash
terraform apply -var web_count=0 -var cache_count=0
terraform apply -replace=module.database.cloudstack_instance.db -var web_count=0 -var cache_count=0
terraform destroy -var web_count=0 -var cache_count=0
```

주의: W9 와 이 코드는 리소스 주소가 다르다(`cloudstack_instance.web[0]` → `module.web.cloudstack_instance.web[0]`).
같은 디렉터리에서 이어 쓰지 말고 W9 를 `destroy` 한 뒤 새 디렉터리에서 시작한다.

