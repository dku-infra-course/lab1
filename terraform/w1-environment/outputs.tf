output "network_id" {
  description = "생성된 격리 네트워크 ID"
  value       = cloudstack_network.lab.id
}

output "network_cidr" {
  description = "격리 네트워크 CIDR"
  value       = cloudstack_network.lab.cidr
}

output "source_nat_ip" {
  description = "가상 라우터 공용 IP. 실습 가이드의 {{PUBLIC_IP}} 값이다"
  value       = data.cloudstack_ipaddress.source_nat.ip_address
}

output "web01_private_ip" {
  description = "web01 사설 IP"
  value       = cloudstack_instance.web01.ip_address
}

output "web02_private_ip" {
  description = "web02 사설 IP (create_web02 = false 이면 빈 문자열)"
  value       = var.create_web02 ? cloudstack_instance.web02[0].ip_address : ""
}

output "ssh_port_web01" {
  description = "web01 SSH 공인 포트"
  value       = tostring(var.ssh_public_port_web01)
}

output "ssh_port_web02" {
  description = "web02 SSH 공인 포트 (create_web02 = false 이면 빈 문자열)"
  value       = var.create_web02 ? tostring(var.ssh_public_port_web02) : ""
}

output "ssh_web01" {
  description = "web01 접속 명령"
  value       = "ssh -p ${var.ssh_public_port_web01} ubuntu@${data.cloudstack_ipaddress.source_nat.ip_address}"
}

output "ssh_web02" {
  description = "web02 접속 명령 (create_web02 = false 이면 빈 문자열)"
  value       = var.create_web02 ? "ssh -p ${var.ssh_public_port_web02} ubuntu@${data.cloudstack_ipaddress.source_nat.ip_address}" : ""
}

output "port_check_web01" {
  description = "포트 도달 확인 명령 (로컬에서 실행)"
  value       = "nc -vz ${data.cloudstack_ipaddress.source_nat.ip_address} ${var.ssh_public_port_web01}"
}
