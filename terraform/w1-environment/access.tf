# W1 실습 가이드 7~9단계: Egress 규칙 / 포트포워딩 / 방화벽.
#
# 알려진 provider 버그 우회:
# cloudstack_network 의 source_nat_ip_id / source_nat_ip_address 는 provider 0.5.0 에서
# apply 후에도 null 로 남는다. 그래서 이미 자동 할당된 Source NAT 공용 IP 를
# data "cloudstack_ipaddress" 로 조회한다 (zone_name + is_source_nat 필터).
# 이 IP 는 네트워크가 Implemented 상태가 되어야 생기므로 depends_on 으로 순서를 보장한다.
#
# 주의: 계정에 공용 IP 가 여러 개면 이 필터가 모호해질 수 있다.
# 그 경우 콘솔에서 IP 를 확인해 filter 를 ip_address 로 바꾼다.

data "cloudstack_ipaddress" "source_nat" {
  filter {
    name  = "zone_name"
    value = var.zone_name
  }

  filter {
    name  = "is_source_nat"
    value = "true"
  }

  depends_on = [cloudstack_instance.web01, cloudstack_instance.web02]
}

resource "cloudstack_port_forward" "ssh" {
  ip_address_id = data.cloudstack_ipaddress.source_nat.id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = var.ssh_public_port_web01
    virtual_machine_id = cloudstack_instance.web01.id
  }

  dynamic "forward" {
    for_each = var.create_web02 ? [1] : []

    content {
      protocol           = "tcp"
      private_port       = 22
      public_port        = var.ssh_public_port_web02
      virtual_machine_id = cloudstack_instance.web02[0].id
    }
  }
}

resource "cloudstack_firewall" "ingress_ssh" {
  ip_address_id = data.cloudstack_ipaddress.source_nat.id

  rule {
    cidr_list = [var.ssh_allowed_cidr]
    protocol  = "tcp"
    ports     = var.create_web02 ? ["${var.ssh_public_port_web01}-${var.ssh_public_port_web02}"] : [tostring(var.ssh_public_port_web01)]
  }
}

# 격리 네트워크는 기본적으로 아웃바운드가 막혀 있어 이 규칙이 없으면 apt update 가 실패한다.
# 실습 가이드 4단계(Egress 규칙)에 대응한다. 운영에서는 목적지·포트를 최소로 좁힌다.
resource "cloudstack_egress_firewall" "egress" {
  network_id = cloudstack_network.lab.id

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
