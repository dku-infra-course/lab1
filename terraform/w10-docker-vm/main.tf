resource "cloudstack_instance" "docker" {
  name             = "docker-${var.name_prefix}"
  display_name     = "docker-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.medium.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_gb
  expunge          = true

  user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
    vm_password = var.vm_password
  })
}
