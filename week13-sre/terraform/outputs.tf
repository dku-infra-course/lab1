# 실측 전
output "cluster_name" {
  description = "생성된 클러스터 이름"
  value       = cloudstack_kubernetes_cluster.k8s.name
}

output "worker_count" {
  description = "현재 코드가 선언한 worker 수"
  value       = var.worker_count
}

output "next_step" {
  description = "kubeconfig는 provider 0.5.x에 데이터 소스가 없어 콘솔에서 내려받는다"
  value       = "콘솔 Kubernetes > 클러스터 > Download kubeconfig 후 chmod 600 ~/.kube/config"
}
