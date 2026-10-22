output "ip" {
  description = "DB 서버 사설 IP"
  value       = cloudstack_instance.db.ip_address
}
