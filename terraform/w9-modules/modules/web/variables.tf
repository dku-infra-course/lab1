variable "instance_count" {
  description = "웹 서버 대수"
  type        = number
  default     = 2
}
variable "name_prefix" { type = string }
variable "network_id" { type = string }
variable "zone" { type = string }
variable "template_id" { type = string }
variable "offering_id" { type = string }
variable "root_disk_size" {
  type    = number
  default = 20
}
variable "user_data" { type = string }
