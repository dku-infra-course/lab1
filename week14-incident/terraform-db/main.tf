# 실측 전
# 9주차 db 모듈과 같은 구성: Medium, Ubuntu_24.04, mariadb-server를 cloud-init으로 설치
data "cloudstack_zone" "dku" {
  filter {
    name  = "name"
    value = "DKU"
  }
}

data "cloudstack_template" "ubuntu" {
  template_filter = "featured"

  filter {
    name  = "name"
    value = "^Ubuntu_24.04$"
  }
}

data "cloudstack_service_offering" "medium" {
  filter {
    name  = "name"
    value = "Medium"
  }
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

  user_data = <<-EOT
    #cloud-config
    password: ${var.vm_password}
    chpasswd:
      expire: false
    ssh_pwauth: true
    package_update: true
    packages:
      - mariadb-server
    runcmd:
      - systemctl enable --now mariadb
      - mkdir -p /var/backups/dku
  EOT
}
