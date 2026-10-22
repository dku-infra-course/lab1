output "web_ips" {
  description = "웹 서버 사설 IP 목록"
  value       = cloudstack_instance.web[*].ip_address
}

output "cache_ip" {
  value = cloudstack_instance.cache.ip_address
}

output "db_ip" {
  value = cloudstack_instance.db.ip_address
}
