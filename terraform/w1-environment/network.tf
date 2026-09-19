# W1 실습 가이드 3단계: 격리 네트워크(Isolated Network) 생성.
# 학생이 콘솔에서 [네트워크] > [네트워크 추가] > Isolated 로 만드는 것과 같은 결과다.
resource "cloudstack_network" "lab" {
  name             = "tf-${var.name_prefix}-net"
  display_text     = "Terraform W1 Environment Lab Network"
  cidr             = var.network_cidr
  network_offering = var.network_offering
  zone             = data.cloudstack_zone.dku.name
}
