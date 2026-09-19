output "shared_network_id" {
  description = "사용한 공용 Shared Network ID"
  value       = var.shared_network_id
}

output "shared_network_name" {
  description = "사용한 공용 Shared Network 이름 (문서용)"
  value       = var.shared_network_name
}

output "webserver_private_ip" {
  description = "백엔드(Flask + Redis) 서버 사설 IP"
  value       = cloudstack_instance.webserver.ip_address
}

output "cache_private_ip" {
  description = "캐시(Nginx + Squid) 서버 사설 IP"
  value       = cloudstack_instance.cache.ip_address
}

output "ssh_webserver" {
  description = "webserver 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.webserver.ip_address}"
}

output "ssh_cache" {
  description = "cache 접속 명령"
  value       = "ssh ubuntu@${cloudstack_instance.cache.ip_address}"
}

output "backend_url" {
  description = "Flask 앱 직접 호출 URL (앱을 기동한 뒤)"
  value       = "http://${cloudstack_instance.webserver.ip_address}:5000/api/products"
}

output "nginx_cache_url" {
  description = "Nginx 리버스 프록시 캐시 경유 URL (캐시 설정을 마친 뒤)"
  value       = "http://${cloudstack_instance.cache.ip_address}/api/products"
}

output "squid_proxy" {
  description = "Squid 포워드 프록시 주소"
  value       = "http://${cloudstack_instance.cache.ip_address}:3128"
}

output "app_code_preinstalled" {
  description = "app.py 와 backend-app 서비스가 미리 배치되었는지"
  value       = var.preinstall_app_code
}

output "cache_config_preinstalled" {
  description = "Nginx/Squid 캐시 설정이 미리 배치되었는지"
  value       = var.preinstall_cache_config
}
