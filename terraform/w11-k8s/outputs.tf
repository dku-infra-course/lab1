output "cluster_name" {
  description = "생성된 클러스터 이름"
  value       = cloudstack_kubernetes_cluster.k8s.name
}

output "state" {
  description = "클러스터 상태. Running 이면 kubeconfig 를 내려받는다"
  value       = cloudstack_kubernetes_cluster.k8s.state
}

# 노드 IP 는 Terraform 으로 읽을 수 없다. 콘솔 > 컴퓨트 > 인스턴스에서 k8s-<학번>-control 로 시작하는 VM 의 IP 를 확인한다.
output "next_steps" {
  description = "클러스터가 Running 이 된 뒤의 접속 안내"
  value       = <<-EOT
    1) 콘솔 > 컴퓨트 > 인스턴스에서 ${cloudstack_kubernetes_cluster.k8s.name}-control 로 시작하는 VM 의 IP 를 확인한다
    2) VPN 연결 후 접속:  ssh cloud@<컨트롤 노드 IP>
    3) 접속 후 도구 설치와 kubectl 연결은 week11-k8s/README.md 를 따른다
  EOT
}
