# 1단계: CKS 클러스터를 만든다 (cloudstack provider).
# 자격증명은 terraform.tfvars 에만 둔다(.gitignore 대상).
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
