resource "cloudstack_kubernetes_cluster" "k8s" {
  name               = "k8s-${var.name_prefix}"
  zone               = var.zone_name
  kubernetes_version = var.kubernetes_version_name
  service_offering   = var.service_offering_name
  size               = var.worker_size
  control_nodes_size = var.control_nodes_size
  network_id         = var.shared_network_id
  noderootdisksize   = var.node_root_disk_gb
  keypair            = var.keypair_name # 선택(null 이면 키 없이 생성)
  description        = "W11 Terraform"
}
