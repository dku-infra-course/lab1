# 실측 전
variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "API Key. terraform.tfvars에만 적고 저장소에 올리지 않는다"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Secret Key. terraform.tfvars에만 적고 저장소에 올리지 않는다"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "학번. 클러스터 이름 접미사로 쓴다"
  type        = string
}

variable "shared_network_id" {
  description = "붙일 Shared Network의 ID. 비우면 격리망이 생겨 클러스터 생성이 멈춘다"
  type        = string

  validation {
    condition     = length(var.shared_network_id) > 0
    error_message = "shared_network_id는 필수다. 콘솔 Networks 상세 화면에서 복사한다."
  }
}

variable "worker_count" {
  description = "worker 노드 수. 13주차는 1, 14주차 개선(SPOF 제거)에서 2로 올린다"
  type        = number
  default     = 1
}

variable "kubernetes_version" {
  description = "CKS 템플릿 이름. 콘솔 Kubernetes 버전 목록과 같아야 한다"
  type        = string
  default     = "Kubernetes_1.32.5_with_Calico"
}
