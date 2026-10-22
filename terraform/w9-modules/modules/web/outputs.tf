output "ips" {
  description = "웹 서버 사설 IP 목록"
  value       = cloudstack_instance.web[*].ip_address
}
