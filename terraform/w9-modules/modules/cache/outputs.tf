output "ip" {
  description = "캐시 서버 사설 IP (0대면 null)"
  value       = try(cloudstack_instance.cache[0].ip_address, null)
}
output "ips" {
  description = "캐시 서버 사설 IP 목록"
  value       = cloudstack_instance.cache[*].ip_address
}
