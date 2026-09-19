# W1 실습 가이드 5단계: VM 배포.
#
# W1 은 "순수 환경만" 만든다. cloud-init 은 비밀번호 로그인을 켜는 것 외에
# 아무 패키지도 설치하지 않는다. apt update 가 되는지(Egress 확인), Apache 설치 등은
# 학생이 콘솔·SSH 에서 직접 하는 학습 대상이므로 자동화하지 않는다.

resource "cloudstack_instance" "web01" {
  name             = "web01-${var.name_prefix}"
  display_name     = "web01-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = cloudstack_network.lab.id
  ip_address       = var.web01_ip
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
  network_id       = cloudstack_network.lab.id
  ip_address       = var.web02_ip
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
