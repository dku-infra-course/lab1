# 노드 접속용 SSH 키페어. 클러스터에 연결해야 노드에 키가 들어간다.
resource "cloudstack_ssh_keypair" "k8s" {
  name       = "k8s-${var.name_prefix}"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "cloudstack_kubernetes_cluster" "k8s" {
  name               = "k8s-${var.name_prefix}"
  zone               = var.zone_name
  kubernetes_version = var.kubernetes_version_name
  service_offering   = var.service_offering_name
  size               = var.worker_size
  control_nodes_size = var.control_nodes_size
  network_id         = var.shared_network_id
  noderootdisksize   = var.node_root_disk_gb
  keypair            = cloudstack_ssh_keypair.k8s.name
  description        = "W11 Terraform"
}
