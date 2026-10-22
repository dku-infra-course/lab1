terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.5.0"
    }
  }
}

resource "cloudstack_instance" "db" {
  name             = "db-${var.name_prefix}"
  display_name     = "db-${var.name_prefix}"
  service_offering = var.offering_id
  network_id       = var.network_id
  template         = var.template_id
  zone             = var.zone
  root_disk_size   = var.disk_size
  expunge          = true
  user_data        = var.user_data
}
