# DKU Solid Cloud (Apache CloudStack) provider 설정.
#
# 자격증명은 코드에 넣지 않는다. terraform.tfvars.example 을 terraform.tfvars 로
# 복사한 뒤 그 안에 api_key/secret_key 값만 채운다(.gitignore 대상이라 커밋되지 않는다).
# OS마다 문법이 다른 환경변수 방식은 쓰지 않는다.

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
