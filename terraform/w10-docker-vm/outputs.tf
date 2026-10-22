output "docker_vm_ip" {
  description = "Docker 실습 VM 사설 IP (VPN 연결 후 ssh ubuntu@IP)"
  value       = cloudstack_instance.docker.ip_address
}

output "next_steps" {
  description = "접속과 대기 안내. cloud-init 이 끝난 뒤에 로그인해야 docker 그룹이 적용된다"
  value       = <<-EOT
    1) VPN 연결 후 접속:  ssh ubuntu@${cloudstack_instance.docker.ip_address}
    2) 설치 완료 대기:    cloud-init status --wait    (done 이 나올 때까지)
    3) 다시 로그인:       exit 후 ssh 재접속 (또는 newgrp docker)
    4) 확인:              docker run --rm hello-world
  EOT
}
