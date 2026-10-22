# 루트 모듈은 모듈을 호출하는 일만 한다.
# 조회한 값(zone·template·offering)은 모듈에 입력으로 넘긴다.

locals {
  user_data = {
    for role, pkgs in {
      web   = ["apache2", "curl"]
      cache = ["redis-server"]
      db    = ["mariadb-server"]
      } : role => templatefile("${path.module}/templates/cloud-init.tftpl", {
        role                      = role
        packages                  = pkgs
        vm_password               = var.vm_password
        extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
    })
  }
}

module "web" {
  source = "./modules/web"

  instance_count = var.web_count
  name_prefix    = var.name_prefix
  network_id     = var.shared_network_id
  zone           = data.cloudstack_zone.dku.name
  template_id    = data.cloudstack_template.ubuntu.id
  offering_id    = data.cloudstack_service_offering.small.id
  user_data      = local.user_data["web"]
}

module "cache" {
  source = "./modules/cache"

  instance_count = var.cache_count
  name_prefix    = var.name_prefix
  network_id     = var.shared_network_id
  zone           = data.cloudstack_zone.dku.name
  template_id    = data.cloudstack_template.ubuntu.id
  offering_id    = data.cloudstack_service_offering.small.id
  user_data      = local.user_data["cache"]
}

module "database" {
  source = "./modules/database"

  name_prefix = var.name_prefix
  network_id  = var.shared_network_id
  zone        = data.cloudstack_zone.dku.name
  template_id = data.cloudstack_template.ubuntu.id
  offering_id = data.cloudstack_service_offering.medium.id
  disk_size   = 20
  user_data   = local.user_data["db"]
}
