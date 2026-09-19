output "shared_network_id" {
  description = "사용한 공용 Shared Network ID"
  value       = var.shared_network_id
}

output "shared_network_name" {
  description = "사용한 공용 Shared Network 이름 (문서용)"
  value       = var.shared_network_name
}

output "lb_private_ip" {
  description = "로드밸런서(Nginx) 사설 IP"
  value       = cloudstack_instance.lb.ip_address
}

output "web01_private_ip" {
  description = "백엔드 web01 사설 IP"
  value       = cloudstack_instance.web01.ip_address
}

output "web02_private_ip" {
  description = "백엔드 web02 사설 IP"
  value       = cloudstack_instance.web02.ip_address
}

output "ssh_lb" {
  description = "lb 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.lb.ip_address}"
}

output "ssh_web01" {
  description = "web01 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.web01.ip_address}"
}

output "ssh_web02" {
  description = "web02 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.web02.ip_address}"
}

output "lb_url" {
  description = "LB 진입 URL. 반복 호출하면 백엔드가 번갈아 응답한다 (LB 설정을 마친 뒤)"
  value       = "http://${cloudstack_instance.lb.ip_address}/"
}

output "lb_config_preinstalled" {
  description = "nginx upstream 설정이 미리 배치되었는지. false 면 Nginx 만 설치된 상태다"
  value       = var.preinstall_lb_config
}

# ---------------------------------------------------------------------------
# B3(IPVS) 랩 출력값. enable_ipvs_lab = false 면 전부 null.
# ---------------------------------------------------------------------------

output "ipvs_source_nat_ip" {
  description = "IPVS 랩 격리 네트워크의 공용(Source NAT) IP"
  value       = var.enable_ipvs_lab ? data.cloudstack_ipaddress.ipvs_source_nat[0].ip_address : null
}

output "ipvs_web01_private_ip" {
  description = "IPVS 랩 web01 사설 IP"
  value       = var.enable_ipvs_lab ? cloudstack_instance.ipvs_web01[0].ip_address : null
}

output "ipvs_web02_private_ip" {
  description = "IPVS 랩 web02 사설 IP"
  value       = var.enable_ipvs_lab ? cloudstack_instance.ipvs_web02[0].ip_address : null
}

output "ipvs_director_private_ip" {
  description = "IPVS/LVS 디렉터 VM 사설 IP"
  value       = var.enable_ipvs_lab ? cloudstack_instance.ipvs_director[0].ip_address : null
}

output "ssh_ipvs_web01" {
  description = "IPVS 랩 web01 접속 명령"
  value       = var.enable_ipvs_lab ? "ssh -p ${var.ipvs_ssh_public_port_web01} ubuntu@${data.cloudstack_ipaddress.ipvs_source_nat[0].ip_address}" : null
}

output "ssh_ipvs_web02" {
  description = "IPVS 랩 web02 접속 명령"
  value       = var.enable_ipvs_lab ? "ssh -p ${var.ipvs_ssh_public_port_web02} ubuntu@${data.cloudstack_ipaddress.ipvs_source_nat[0].ip_address}" : null
}

output "ssh_ipvs_director" {
  description = "IPVS/LVS 디렉터 VM 접속 명령"
  value       = var.enable_ipvs_lab ? "ssh -p ${var.ipvs_ssh_public_port_director} ubuntu@${data.cloudstack_ipaddress.ipvs_source_nat[0].ip_address}" : null
}
