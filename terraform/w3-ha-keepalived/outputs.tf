output "network_id" {
  description = "생성된 격리 네트워크 ID"
  value       = cloudstack_network.ha_lab.id
}

output "source_nat_ip" {
  description = "가상 라우터 공용 IP (포트포워딩 대상)"
  value       = data.cloudstack_ipaddress.source_nat.ip_address
}

output "web01_private_ip" {
  description = "web01(MASTER, priority 110) 사설 IP"
  value       = cloudstack_instance.web01.ip_address
}

output "web02_private_ip" {
  description = "web02(BACKUP, priority 100) 사설 IP"
  value       = cloudstack_instance.web02.ip_address
}

output "vip" {
  description = "Keepalived VIP"
  value       = var.vip
}

output "vrrp_interface" {
  description = "VRRP 인터페이스 이름 (keepalived.conf 의 interface 값)"
  value       = var.vrrp_interface
}

output "ssh_port_web01" {
  description = "web01 SSH 공인 포트"
  value       = tostring(var.ssh_public_port_web01)
}

output "ssh_port_web02" {
  description = "web02 SSH 공인 포트"
  value       = tostring(var.ssh_public_port_web02)
}

output "ssh_web01" {
  description = "web01(MASTER) 접속 명령"
  value       = "ssh -p ${var.ssh_public_port_web01} ubuntu@${data.cloudstack_ipaddress.source_nat.ip_address}"
}

output "ssh_web02" {
  description = "web02(BACKUP) 접속 명령"
  value       = "ssh -p ${var.ssh_public_port_web02} ubuntu@${data.cloudstack_ipaddress.source_nat.ip_address}"
}

output "keepalived_config_preinstalled" {
  description = "keepalived 설정이 미리 배치되었는지. false 면 설치만 된 상태다"
  value       = var.preinstall_keepalived_config
}
