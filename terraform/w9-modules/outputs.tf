output "web_ips" {
  value = module.web.ips
}
output "cache_ip" {
  value = module.cache.ip
}
output "db_ip" {
  value = module.database.ip
}

# Ansible 인벤토리 형식. terraform output -raw ansible_inventory > inventory.ini
output "ansible_inventory" {
  value = <<-EOT
    [web]
    %{for ip in module.web.ips~}
    ${ip}
    %{endfor~}

    [cache]
    %{for ip in module.cache.ips~}
    ${ip}
    %{endfor~}

    [db]
    ${module.database.ip}

    [all:vars]
    ansible_user=ubuntu
  EOT
}
