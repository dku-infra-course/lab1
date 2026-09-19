# webserver(앱 + Redis) 1대 + cache(Nginx + Squid) 1대.
#
# cloud-init 이 하는 일 (기본값)
#   - webserver: python3-pip, python3-flask, python3-redis, redis-server 설치
#   - cache    : nginx, squid 설치
#
# 앱 코드 배치, Redis 보안 설정(bind / requirepass), Nginx 캐시 존과 프록시 설정,
# Squid cache_dir 은 모두 실습_W5_캐시.html 의 학습 대상이므로 기본값에서는 넣지 않는다.
# 강사가 캐시 효과만 빠르게 재측정하려면 preinstall_* 변수를 true 로 둔다.
#
# Shared Network 를 쓰므로 IP 는 DHCP 로 10.0.X.X 가 할당된다.
# cache 의 Nginx 는 webserver 의 5000 포트를 upstream 으로 쓰므로,
# cache 쪽 설정에는 webserver 의 실제 할당 IP 가 들어간다.

locals {
  # labs/week05-cache 의 원본을 그대로 재사용하고 자리표시자만 치환한다.
  app_py           = file("${path.module}/files/app.py")
  nginx_cache_conf = replace(file("${path.module}/files/nginx-cache.conf"), "{{WEBSERVER_IP}}", cloudstack_instance.webserver.ip_address)
  nginx_cache_zone = file("${path.module}/files/nginx-cache-zone.conf")
  squid_snippet    = replace(file("${path.module}/files/squid.conf.snippet"), "{{WEBSERVER_IP}}", cloudstack_instance.webserver.ip_address)

  # Redis 보안 설정. redis_password 가 빈 문자열이면 아예 쓰지 않는다.
  # sed 로 기존 줄을 고치는 대신 별도 파일을 append 한다(비밀번호에 특수문자가 있어도 안전).
  redis_extra_conf = "# DKU lab 추가 설정 (실습_W5_캐시.html Part 2)\nbind 127.0.0.1 ::1\nrequirepass ${var.redis_password}\n"

  # backend-app systemd 유닛. requirepass 를 설정한 경우에만 환경변수를 넘긴다.
  # heredoc 대신 join 으로 만든다(들여쓰기가 유닛 파일에 섞이지 않게 하려는 것).
  backend_service_unit = join("\n", [
    "[Unit]",
    "Description=Flask Backend Server",
    "After=network.target redis-server.service",
    "",
    "[Service]",
    "Type=simple",
    "User=ubuntu",
    "WorkingDirectory=/home/ubuntu/backend-app",
    "ExecStart=/usr/bin/python3 /home/ubuntu/backend-app/app.py",
    "Restart=always",
    var.redis_password != "" ? "Environment=REDIS_PASSWORD=${var.redis_password}" : "# requirepass 를 설정하지 않았으므로 REDIS_PASSWORD 를 넘기지 않는다",
    "",
    "[Install]",
    "WantedBy=multi-user.target",
    "",
  ])
}

resource "cloudstack_instance" "webserver" {
  name             = "webserver-${var.name_prefix}"
  display_name     = "webserver-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/webserver.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_app            = var.preinstall_app_code
    app_py                    = local.app_py
    set_redis_pass            = var.redis_password != ""
    redis_extra_conf          = local.redis_extra_conf
    backend_service_unit      = local.backend_service_unit
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })
}

resource "cloudstack_instance" "cache" {
  name             = "cache-${var.name_prefix}"
  display_name     = "cache-${var.name_prefix}"
  service_offering = data.cloudstack_service_offering.vm.id
  network_id       = var.shared_network_id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name
  root_disk_size   = var.root_disk_size
  keypair          = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  expunge          = true

  user_data = templatefile("${path.module}/templates/cache.cloudinit.tftpl", {
    vm_password               = var.vm_password
    preinstall_conf           = var.preinstall_cache_config
    nginx_cache_conf          = local.nginx_cache_conf
    nginx_cache_zone          = local.nginx_cache_zone
    squid_snippet             = local.squid_snippet
    webserver_ip              = cloudstack_instance.webserver.ip_address
    extra_ssh_authorized_keys = var.extra_ssh_authorized_keys
  })

  depends_on = [cloudstack_instance.webserver]
}
