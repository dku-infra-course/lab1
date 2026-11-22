# 실측 전
# 11주차 클러스터와 같은 구성. worker_count만 변수로 뺐다.
# 주의: size 변경이 클러스터 재생성 없이 반영되는지는 실측 전(미확인).
#       plan에 'must be replaced'(-/+)가 보이면 apply하지 말고 콘솔 Kubernetes > Scale로 늘린다.
resource "cloudstack_kubernetes_cluster" "k8s" {
  name               = "k8s-${var.name_prefix}"
  zone               = "DKU"
  kubernetes_version = var.kubernetes_version
  service_offering   = "Medium"
  size               = var.worker_count
  control_nodes_size = 1
  network_id         = var.shared_network_id
  noderootdisksize   = 20
}
