variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "CloudStack API Key. 우측 상단 프로필 > 사용자 상세 > API 키 생성"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "CloudStack Secret Key"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "학번. VM 이름 접미사로 쓴다 (예: docker-20241234)"
  type        = string
}

variable "shared_network_id" {
  description = "붙일 Shared Network 의 ID. 콘솔 [네트워크] 상세 화면에서 확인한다"
  type        = string
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호 (실습용). 공백과 따옴표는 피한다"
  type        = string
  default     = "ubuntu"
  sensitive   = true
}

variable "root_disk_gb" {
  description = "루트 디스크 크기 (GB). 이미지 빌드와 Trivy DB 캐시, 여러 이미지를 담는 용도"
  type        = number
  default     = 20
}
