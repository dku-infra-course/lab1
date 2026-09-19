output "shared_network_id" {
  description = "사용한 공용 Shared Network ID"
  value       = var.shared_network_id
}

output "shared_network_name" {
  description = "사용한 공용 Shared Network 이름 (문서용)"
  value       = var.shared_network_name
}

output "web01_private_ip" {
  description = "web01 사설 IP (10.0.X.X). VPN 에서 바로 접속한다"
  value       = cloudstack_instance.web01.ip_address
}

output "web02_private_ip" {
  description = "web02 사설 IP (create_web02 = false 이면 빈 문자열)"
  value       = var.create_web02 ? cloudstack_instance.web02[0].ip_address : ""
}

output "ssh_web01" {
  description = "web01 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.web01.ip_address}"
}

output "ssh_web02" {
  description = "web02 접속 명령 (create_web02 = false 이면 빈 문자열)"
  value       = var.create_web02 ? "ssh ubuntu@${cloudstack_instance.web02[0].ip_address}" : ""
}

output "web01_http_url" {
  description = "Apache 를 설치한 뒤 확인할 URL (실습에서 직접 설치한다)"
  value       = "http://${cloudstack_instance.web01.ip_address}/"
}
