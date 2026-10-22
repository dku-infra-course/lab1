variable "name_prefix" { type = string }
variable "network_id" { type = string }
variable "zone" { type = string }
variable "template_id" { type = string }
variable "offering_id" { type = string }
variable "disk_size" {
  description = "루트 디스크(GB). Solid Cloud 는 템플릿 크기(20GB)보다 크게 지정해도 20GB 로 만든다. 20 이 아니면 plan 이 매번 교체를 보여준다"
  type        = number
  default     = 20
}
variable "user_data" { type = string }
