data "cloudstack_zone" "dku" {
  filter {
    name  = "name"
    value = "DKU"
  }
}

data "cloudstack_template" "ubuntu" {
  template_filter = "featured"
  filter {
    name  = "name"
    value = "^Ubuntu_24.04$"
  }
}

# 이미지 빌드와 스캔에는 Medium(2 vCPU / 4GB) 이상을 권장한다.
data "cloudstack_service_offering" "medium" {
  filter {
    name  = "name"
    value = "Medium"
  }
}
