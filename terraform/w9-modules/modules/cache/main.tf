terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.5.0"
    }
  }
}

# 기존 state 의 주소(cloudstack_instance.cache)를 count 주소([0])로 옮겨 VM 이 재생성되지 않게 한다
moved {
  from = cloudstack_instance.cache
  to   = cloudstack_instance.cache[0]
}

resource "cloudstack_instance" "cache" {
  count = var.instance_count

  name             = "cache-${var.name_prefix}"
  display_name     = "cache-${var.name_prefix}"
  service_offering = var.offering_id
  network_id       = var.network_id
  template         = var.template_id
  zone             = var.zone
  root_disk_size   = var.root_disk_size
  expunge          = true
  user_data        = var.user_data
}
