# 포트포워딩 / 방화벽 / Egress.
#
# 알려진 provider 버그 우회:
# cloudstack_network 의 source_nat_ip_id / source_nat_ip_address 가 provider 0.5.0 에서
# null 로 오기 때문에, 이미 자동 할당된 Source NAT 공용 IP 를 data source 로 조회한다.
# (zone_name + is_source_nat 필터. pretest 에서 실제 배포로 검증된 방식이다)
# 이 IP 는 네트워크가 Implemented 상태가 되어야 생기므로 depends_on 으로 순서를 보장한다.
#
# 계정에 공용 IP 가 여러 개면 필터가 모호해질 수 있다. 그때는 콘솔에서 IP 를 확인해
# filter 를 ip_address 로 바꾼다.

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

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = var.ssh_public_port_web02
    virtual_machine_id = cloudstack_instance.web02.id
  }
}

resource "cloudstack_firewall" "ingress_ssh" {
  ip_address_id = data.cloudstack_ipaddress.source_nat.id

  rule {
    cidr_list = [var.ssh_allowed_cidr]
    protocol  = "tcp"
    ports     = ["${var.ssh_public_port_web01}-${var.ssh_public_port_web02}"]
  }
}

# 패키지 설치(apt)와 DNS 조회를 위한 아웃바운드 허용.
# VRRP(멀티캐스트 224.0.0.18, IP protocol 112)는 같은 서브넷 안에서 주고받는 트래픽이라
# Egress 규칙과 무관하다. 따라서 VRRP 용 별도 규칙은 넣지 않는다.
resource "cloudstack_egress_firewall" "egress" {
  network_id = cloudstack_network.ha_lab.id

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
