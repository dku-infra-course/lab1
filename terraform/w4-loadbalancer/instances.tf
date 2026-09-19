# 백엔드 웹서버 2대(web01/web02) + 로드밸런서 1대(lb).
#
# cloud-init 이 하는 일
#   - 백엔드: Apache 설치 + 서버 구분 페이지 생성 (어느 백엔드가 응답했는지 눈으로 구분)
#   - lb    : Nginx "설치만". upstream / weight / least_conn / ip_hash / 헬스체크 설정은
#             실습_W4_로드밸런싱.html 의 학습 대상이므로 남겨 둔다.
#
# Shared Network 를 쓰므로 IP 는 DHCP 로 10.0.X.X 가 할당된다. VPN 에서 직접 SSH 가 되고,
# lb 는 내부 IP 로 백엔드에 curl 한다.
#
# preinstall_lb_config = true 로 두면 labs/week04-loadbalancer/nginx-lb.conf 를
# 그대로 가져와 {{WEB01_IP}} / {{WEB02_IP}} 만 실제 할당 IP 로 치환해 배치한다.

locals {
  nginx_lb_conf = replace(replace(file("${path.module}/files/nginx-lb.conf"), "{{WEB01_IP}}", cloudstack_instance.web01.ip_address), "{{WEB02_IP}}", cloudstack_instance.web02.ip_address)
}

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

  user_data = templatefile("${path.module}/templates/backend.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = var.preinstall_packages
    role                      = "web01"
    page_label                = var.web01_page_label
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "web02" {
  name             = "web02-${var.name_prefix}"
  display_name     = "web02-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/backend.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = var.preinstall_packages
    role                      = "web02"
    page_label                = var.web02_page_label
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "lb" {
  name             = "lb-${var.name_prefix}"
  display_name     = "lb-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/lb.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = var.preinstall_packages
    preinstall_conf           = var.preinstall_lb_config
    nginx_lb_conf             = local.nginx_lb_conf
    web01_ip                  = cloudstack_instance.web01.ip_address
    web02_ip                  = cloudstack_instance.web02.ip_address
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })

  depends_on = [cloudstack_instance.web01, cloudstack_instance.web02]
}
