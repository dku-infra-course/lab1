# 9주차 Terraform 실습: provider 설정
# 자격증명은 코드에 적지 않는다. terraform.tfvars(.gitignore 대상) 또는 TF_VAR_* 환경변수로 받는다.
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
