# 3-Tier: 웹(count) + 캐시 + DB. 1주차 도식, 3주차 이중화, 5주차 캐시 계층을 코드로 옮긴다.

resource "cloudstack_instance" "web" {
  count = var.web_count

  name             = "web-${count.index + 1}-${var.name_prefix}"
  display_name     = "web-${count.index + 1}-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.small.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = 20
  expunge          = true

  user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
    role                      = "web"
    packages                  = ["apache2", "curl"]
    vm_password               = var.vm_password
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "cache" {
  name             = "cache-${var.name_prefix}"
  display_name     = "cache-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.small.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = 20
  expunge          = true

  user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
    role                      = "cache"
    packages                  = ["redis-server"]
    vm_password               = var.vm_password
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "db" {
  name             = "db-${var.name_prefix}"
  display_name     = "db-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.medium.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = 20
  expunge          = true

  user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
    role                      = "db"
    packages                  = ["mariadb-server"]
    vm_password               = var.vm_password
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}
