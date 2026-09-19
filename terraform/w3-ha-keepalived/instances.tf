# web01(MASTER/Active) · web02(BACKUP) 2대.
#
# cloud-init 이 하는 일
#   - Apache 설치, 서버별 구분 페이지 생성 (web01: Active Server / web02: Backup Server)
#   - keepalived 는 "설치만" 한다. 패키지 설치 직후 자동 기동되지 않도록 정지·비활성화한다.
#     (Ubuntu 의 keepalived 패키지는 설정 파일을 만들지 않아 그대로 두면 실패 상태로 남는다)
#
# keepalived.conf 배치와 서비스 기동은 실습_W3_이중화.html 의 학습 대상이므로
# 기본값(preinstall_keepalived_config = false)에서는 수동으로 남긴다.
# 강사가 failover 만 빠르게 재확인하려면 true 로 두고 apply 한다.

locals {
  # labs/week03-ha-keepalived 의 설정 원본을 그대로 재사용하고
  # 자리표시자({{IFACE}} / {{VIP}} / {{WEB01_IP}} / {{WEB02_IP}})만 치환한다.
  conf_src_web01 = file("${path.module}/files/${var.keepalived_use_unicast ? "keepalived-unicast-web01.conf" : "keepalived-web01.conf"}")
  conf_src_web02 = file("${path.module}/files/${var.keepalived_use_unicast ? "keepalived-unicast-web02.conf" : "keepalived-web02.conf"}")

  keepalived_conf_web01 = replace(replace(replace(replace(local.conf_src_web01, "{{IFACE}}", var.vrrp_interface), "{{VIP}}", var.vip), "{{WEB01_IP}}", var.web01_ip), "{{WEB02_IP}}", var.web02_ip)
  keepalived_conf_web02 = replace(replace(replace(replace(local.conf_src_web02, "{{IFACE}}", var.vrrp_interface), "{{VIP}}", var.vip), "{{WEB01_IP}}", var.web01_ip), "{{WEB02_IP}}", var.web02_ip)
}

resource "cloudstack_instance" "web01" {
  name             = "web01-${var.name_prefix}"
  display_name     = "web01-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = cloudstack_network.ha_lab.id
  ip_address       = var.web01_ip
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/web.cloudinit.tftpl", {
    vm_password               = var.vm_password
    page_title                = "Active Server"
    role                      = "web01"
    preinstall_packages       = var.preinstall_packages
    preinstall_conf           = var.preinstall_keepalived_config
    keepalived_conf           = local.keepalived_conf_web01
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "web02" {
  name             = "web02-${var.name_prefix}"
  display_name     = "web02-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = cloudstack_network.ha_lab.id
  ip_address       = var.web02_ip
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/web.cloudinit.tftpl", {
    vm_password               = var.vm_password
    page_title                = "Backup Server"
    role                      = "web02"
    preinstall_packages       = var.preinstall_packages
    preinstall_conf           = var.preinstall_keepalived_config
    keepalived_conf           = local.keepalived_conf_web02
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}
