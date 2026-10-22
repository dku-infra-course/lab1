# 이미 있는 값을 읽어 온다 (조회 전용)
data "cloudstack_zone" "dku" {
  filter {
    name  = "name"
    value = "DKU"
  }
}

data "cloudstack_template" "ubuntu" {
  template_filter = "featured"

  # filter.value 는 정규식이다. 앵커(^$)가 없으면 Ubuntu_24.04_VSCode 같은 다른 템플릿이 걸릴 수 있다.
  filter {
    name  = "name"
    value = "^Ubuntu_24.04$"
  }
}

data "cloudstack_service_offering" "small" {
  filter {
    name  = "name"
    value = "Small"
  }
}

data "cloudstack_service_offering" "medium" {
  filter {
    name  = "name"
    value = "Medium"
  }
}
