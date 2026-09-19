# 선택·심화 B3(IPVS/LVS 로드밸런서) 전용 환경.
#
# 이번 주 본 실습(web01·web02·lb, Shared Network)과 완전히 별개다. B3는 NIC에
# 원래 할당되지 않은 가상 IP(VIP)를 얹는 실습이라 Shared Network에서는 다른
# 학생과 IP 충돌·스푸핑 방지 정책에 걸릴 수 있다(FINDINGS.md 참고). 그래서
# 3주차와 같은 CIDR·주소 관례(192.168.0.0/24)의 격리 네트워크를 새로 만든다.
# 3주차 것을 이어 쓰는 게 아니라 매번 새로 만들고 끝나면 정리(destroy)하는
# 것을 원칙으로 한다(이 프로젝트의 "매주 정리" 원칙과 동일).
#
# enable_ipvs_lab = false(기본값)면 이 파일의 리소스는 전부 만들어지지 않는다.

resource "cloudstack_network" "ipvs_lab" {
  count = var.enable_ipvs_lab ? 1 : 0

  name             = "tf-${var.name_prefix}-ipvs-net"
  display_text     = "W4 B3 IPVS Lab Network (선택 심화)"
  cidr             = var.ipvs_network_cidr
  network_offering = "DefaultIsolatedNetworkOfferingWithSourceNatService"
  zone             = data.cloudstack_zone.dku.name
}

resource "cloudstack_instance" "ipvs_web01" {
  count = var.enable_ipvs_lab ? 1 : 0

  name             = "ipvs-web01-${var.name_prefix}"
  display_name     = "ipvs-web01-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.ipvs[0].id
  network_id       = cloudstack_network.ipvs_lab[0].id
  ip_address       = var.ipvs_web01_ip
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/backend.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = var.ipvs_preinstall_packages
    role                      = "ipvs-web01"
    page_label                = "Web Server 01"
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "ipvs_web02" {
  count = var.enable_ipvs_lab ? 1 : 0

  name             = "ipvs-web02-${var.name_prefix}"
  display_name     = "ipvs-web02-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.ipvs[0].id
  network_id       = cloudstack_network.ipvs_lab[0].id
  ip_address       = var.ipvs_web02_ip
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/backend.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = var.ipvs_preinstall_packages
    role                      = "ipvs-web02"
    page_label                = "Web Server 02"
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

# IPVS/LVS 를 직접 다룰 VM. 패키지는 항상 학생이 설치한다(preinstall 토글 없음,
# ipvsadm 설치·모듈 로드·VIP 조작 자체가 이 실습의 학습 대상이다).
resource "cloudstack_instance" "ipvs_director" {
  count = var.enable_ipvs_lab ? 1 : 0

  name             = "ipvs-director-${var.name_prefix}"
  display_name     = "ipvs-director-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.ipvs[0].id
  network_id       = cloudstack_network.ipvs_lab[0].id
  ip_address       = var.ipvs_director_ip
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/backend.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_packages       = false
    role                      = "ipvs-director"
    page_label                = ""
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

# W1·W3와 같은 이유로 이름 기반 조회 대신 is_source_nat 필터로 공용 IP를 찾는다.
# 계정에 활성 격리 네트워크가 이것 하나뿐일 때만 모호하지 않다(보통 그렇다,
# 이 프로젝트는 주차마다 정리하는 것이 원칙이라 동시에 여러 개가 떠 있지 않다).
data "cloudstack_ipaddress" "ipvs_source_nat" {
  count = var.enable_ipvs_lab ? 1 : 0

  filter {
    name  = "zone_name"
    value = var.zone_name
  }

  filter {
    name  = "is_source_nat"
    value = "true"
  }

  depends_on = [
    cloudstack_instance.ipvs_web01,
    cloudstack_instance.ipvs_web02,
    cloudstack_instance.ipvs_director,
  ]
}

resource "cloudstack_port_forward" "ipvs_ssh" {
  count = var.enable_ipvs_lab ? 1 : 0

  ip_address_id = data.cloudstack_ipaddress.ipvs_source_nat[0].id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = var.ipvs_ssh_public_port_web01
    virtual_machine_id = cloudstack_instance.ipvs_web01[0].id
  }

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = var.ipvs_ssh_public_port_web02
    virtual_machine_id = cloudstack_instance.ipvs_web02[0].id
  }

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = var.ipvs_ssh_public_port_director
    virtual_machine_id = cloudstack_instance.ipvs_director[0].id
  }
}

resource "cloudstack_firewall" "ipvs_ingress_ssh" {
  count = var.enable_ipvs_lab ? 1 : 0

  ip_address_id = data.cloudstack_ipaddress.ipvs_source_nat[0].id

  rule {
    cidr_list = [var.ssh_allowed_cidr]
    protocol  = "tcp"
    ports     = ["${var.ipvs_ssh_public_port_web01}-${var.ipvs_ssh_public_port_director}"]
  }
}

# 격리 네트워크는 기본적으로 아웃바운드가 막혀 있어 이 규칙이 없으면 apt install 이 실패한다.
resource "cloudstack_egress_firewall" "ipvs_egress" {
  count = var.enable_ipvs_lab ? 1 : 0

  network_id = cloudstack_network.ipvs_lab[0].id

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["80", "443"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "udp"
    ports     = ["53"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "icmp"
    icmp_type = -1
    icmp_code = -1
  }
}
