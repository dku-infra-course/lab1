# 10주차 Docker 실습 VM. 자격증명은 코드에 적지 않는다 (terraform.tfvars 또는 TF_VAR_*).
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
