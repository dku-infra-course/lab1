# 실측 전
# DB VM 1대 (14주차 백업·복원 실습). 클러스터와 별도 state를 쓴다.
terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.5.0"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}
