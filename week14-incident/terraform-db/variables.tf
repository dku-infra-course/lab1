# 실측 전
variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "API Key. terraform.tfvars에만 적는다"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Secret Key. terraform.tfvars에만 적는다"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "학번. VM 이름 접미사"
  type        = string
}

variable "shared_network_id" {
  description = "Shared Network의 ID"
  type        = string
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호(실습용). 실제 값은 tfvars에서 정한다"
  type        = string
  sensitive   = true
}
