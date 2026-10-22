variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "API Key. 우측 상단 프로필 > 사용자 상세 > API 키 생성"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Secret Key"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "학번. VM 이름 접미사로 쓴다 (예: web-1-20241234)"
  type        = string
}

variable "shared_network_id" {
  description = "붙일 Shared Network 의 ID. 콘솔 [네트워크] 상세 화면에서 확인한다"
  type        = string
}

variable "web_count" {
  description = "웹 서버 대수"
  type        = number
  default     = 2
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호 (실습용)"
  type        = string
  default     = "ubuntu"
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init으로 ubuntu 계정에 추가할 공개키 목록 (자동 점검용, 보통 비워 둔다)"
  type        = list(string)
  default     = []
}
