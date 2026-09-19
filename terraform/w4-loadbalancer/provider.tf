# DKU Solid Cloud (Apache CloudStack) provider 설정.
# terraform-w3-ha-pretest / terraform-w4-lb-pretest 에서 실제 배포로 검증된 구성을 그대로 사용한다.
#
# 자격증명은 코드에 넣지 않는다. 아래 두 방법 중 하나를 쓴다.
#   1) terraform.tfvars (.gitignore 대상)
#   2) 환경변수  export TF_VAR_api_key=... ; export TF_VAR_secret_key=...

terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}
