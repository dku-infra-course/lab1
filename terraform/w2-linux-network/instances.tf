# W2 는 순수 Ubuntu 상태로 둔다.
# Apache 설치, 페이지 교체, systemctl enable 은 실습_W2_리눅스네트워크.html 의
# 학습 대상이므로 cloud-init 에서 자동화하지 않는다.
#
# Shared Network 에 붙이므로 IP 는 DHCP 로 10.0.X.X 가 할당된다.
# ip_address 를 지정하지 않고, 할당된 값을 outputs 로 노출한다.
# VPN 을 켠 상태라면 이 사설 IP 로 바로 SSH 가 된다 (포트포워딩 불필요).

resource "cloudstack_instance" "web01" {
  name             = "web01-${var.name_prefix}"
  display_name     = "web01-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/bare.cloudinit.tftpl", {
    vm_password               = var.vm_password
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "web02" {
  count = var.create_web02 ? 1 : 0

  name             = "web02-${var.name_prefix}"
  display_name     = "web02-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/bare.cloudinit.tftpl", {
    vm_password               = var.vm_password
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}
