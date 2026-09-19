# W3 이중화 실습 전용 격리 네트워크.
# VRRP 는 같은 서브넷 안에서만 동작하므로 web01/web02 를 같은 격리 네트워크에 둔다.
#
# 멀티캐스트: DKU Solid Cloud 격리망에서는 기본 설정 그대로 VRRP 멀티캐스트
# (224.0.0.18, IP protocol 112)가 동작하는 것이 pretest 로 검증되었다.
# Egress 방화벽은 네트워크 밖으로 나가는 트래픽에만 적용되고, 같은 서브넷 안의
# VRRP 광고에는 관여하지 않는다. 그래서 VRRP 용 별도 규칙이 필요 없다.
# 만약 양쪽 모두 MASTER 가 되는 split-brain 이 보이면 멀티캐스트가 막힌 경우이므로
# keepalived_use_unicast = true 로 유니캐스트로 전환한다(README 참고).
resource "cloudstack_network" "ha_lab" {
  name             = "tf-${var.name_prefix}-net"
  display_text     = "Terraform W3 HA Keepalived Lab Network"
  cidr             = var.network_cidr
  network_offering = var.network_offering
  zone             = data.cloudstack_zone.dku.name
}
