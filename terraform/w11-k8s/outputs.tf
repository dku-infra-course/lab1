output "cluster_name" {
  description = "생성된 클러스터 이름"
  value       = cloudstack_kubernetes_cluster.k8s.name
}

output "state" {
  description = "클러스터 상태. Running 이면 kubeconfig 를 내려받는다"
  value       = cloudstack_kubernetes_cluster.k8s.state
}

# Shared Network 에서는 공용 IP 가 없어 이 값이 비어 있다.
# API 서버 주소는 콘솔 > 쿠버네티스 > 클러스터 > kubeconfig 의 server: 에서 확인한다.
output "ip_address" {
  description = "클러스터 공용 IP (Shared Network 에서는 비어 있다)"
  value       = cloudstack_kubernetes_cluster.k8s.ip_address
}
