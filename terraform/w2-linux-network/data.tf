# Zone / 템플릿 / 컴퓨트 오퍼링 조회.
# 이 세 개는 pretest 코드에서 실제 배포로 검증된 조회 방식이다.
#
# 참고: provider 0.5.0 에는 network 을 이름으로 찾는 data source 가 없다.
# (제공되는 data source: zone, ipaddress, instance, network_offering, pod,
#  ssh_keypair, service_offering, template, user, vpc, vpn_connection, volume)
# 그래서 Shared Network 를 쓰는 주차는 네트워크 ID 를 변수로 받는다.

data "cloudstack_zone" "dku" {
  filter {
    name  = "name"
    value = var.zone_name
  }
}

data "cloudstack_template" "ubuntu" {
  template_filter = var.template_filter

  # filter.value 는 정규식이다. 앵커(^...$) 없이 "Ubuntu_24.04" 를 주면
  # "Ubuntu_24.04_VSCode-basic" 등 접두사가 같은 다른 템플릿도 매치돼
  # provider 가 그중 하나를 골라 버린다(2026-08-27 실측으로 확인: 앵커 없이는
  # VSCode-basic 이 뽑혔다). 정확히 이 이름만 골라야 하므로 앵커를 반드시 둔다.
  filter {
    name  = "name"
    value = "^${var.template_name}$"
  }
}

data "cloudstack_service_offering" "vm" {
  filter {
    name  = "name"
    value = var.service_offering_name
  }
}
