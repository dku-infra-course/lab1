# 실측 전
output "db_ip" {
  description = "DB VM 사설 IP. backup.sh와 restore.sh 실습에서 ssh 대상으로 쓴다"
  value       = cloudstack_instance.db.ip_address
}
