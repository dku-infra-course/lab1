# ---------------------------------------------------------------------------
# 접속 정보 (자격증명은 terraform.tfvars 또는 TF_VAR_* 환경변수로 받는다)
# ---------------------------------------------------------------------------

variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "CloudStack API Key. 확인됨(2026-08-23): 우측 상단 프로필 > 사용자 상세 > API 키 생성"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "CloudStack Secret Key"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# 공통 환경값
# ---------------------------------------------------------------------------

variable "zone_name" {
  description = "CloudStack Zone 이름"
  type        = string
  default     = "DKU"
}

variable "template_name" {
  description = "VM 템플릿 이름"
  type        = string
  default     = "Ubuntu_24.04"
}

variable "template_filter" {
  description = "템플릿 검색 범위. Ubuntu_24.04 는 featured, Ubuntu_22.04 는 community"
  type        = string
  default     = "featured"
}

variable "service_offering_name" {
  description = "컴퓨트 오퍼링 이름. 확인됨(2026-08-23): Small(1core/2GB) · Medium(2core/4GB) · Large(4core/8GB) · XLarge(8core/16GB) · Custom. W3 가이드가 명시하는 값은 Medium(기본값, web01·web02 동일)"
  type        = string
  default     = "Medium"
}

variable "root_disk_size" {
  description = "루트 디스크 크기 (GB)"
  type        = number
  default     = 20
}

variable "name_prefix" {
  description = "학번이나 강사 식별자. VM 이름은 가이드 표기(web01-{학번})에 맞춰 web01-<name_prefix> 형태로 만들어진다"
  type        = string
  default     = "w3ha"
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호"
  type        = string
  default     = "ubuntu"
}

variable "ssh_keypair_name" {
  description = "CloudStack 에 등록된 SSH 키쌍 이름. 빈 문자열이면 비밀번호 로그인만 사용한다"
  type        = string
  default     = ""
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init 으로 ubuntu 계정에 직접 추가할 공개키 목록. 콘솔 키페어 주입이 안 되는 이 플랫폼에서 자동 검증용 접속을 만들 때만 쓴다. 기본값은 비워 둔다(학생 실습에는 영향 없음)"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# W3: Isolated Network 를 새로 만든다 (VRRP 는 같은 서브넷 안에서 동작한다)
# ---------------------------------------------------------------------------

variable "network_cidr" {
  description = "이중화 실습용 격리 네트워크 CIDR"
  type        = string
  default     = "192.168.0.0/24"
}

variable "network_offering" {
  description = "격리 네트워크 오퍼링"
  type        = string
  default     = "DefaultIsolatedNetworkOfferingWithSourceNatService"
}

variable "vip" {
  description = "Keepalived VIP (가상 IP). 실습 가이드 기준값"
  type        = string
  default     = "192.168.0.100"
}

variable "web01_ip" {
  description = "web01(MASTER, priority 110) 사설 IP"
  type        = string
  default     = "192.168.0.10"
}

variable "web02_ip" {
  description = "web02(BACKUP, priority 100) 사설 IP"
  type        = string
  default     = "192.168.0.11"
}

variable "vrrp_interface" {
  description = "VRRP 패킷을 주고받을 인터페이스 이름. Ubuntu 템플릿 기본값은 ens3 (ip link 로 확인)"
  type        = string
  default     = "ens3"
}

variable "ssh_public_port_web01" {
  description = "web01 SSH 포트포워딩 공인 포트"
  type        = number
  default     = 2201
}

variable "ssh_public_port_web02" {
  description = "web02 SSH 포트포워딩 공인 포트"
  type        = number
  default     = 2202
}

variable "ssh_allowed_cidr" {
  description = "SSH 인바운드 허용 Source CIDR. VPN 대역으로 좁히는 것을 권장. 확인됨(2026-08-23): VPN 대역은 10.8.0.0/24(넷마스크 255.255.255.0)"
  type        = string
  default     = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# W3: 어디까지 미리 만들어 둘지
#
# 기본값(둘 다 false)은 패키지조차 설치하지 않은 순정 Ubuntu다. 학생이 콘솔로
# 직접 만드는 VM과 조건을 맞추기 위한 것이다(녹화·검증 목적으로 조건을 다르게
# 두고 싶을 때만 아래 두 변수를 올린다).
# ---------------------------------------------------------------------------

variable "preinstall_packages" {
  description = "true 로 두면 apache2·keepalived·curl 을 설치만 한다(keepalived 서비스는 꺼진 채로 둔다). 기본값 false"
  type        = bool
  default     = false
}

variable "preinstall_keepalived_config" {
  description = "true 로 두면 패키지 설치까지 포함해서 keepalived.conf 배치와 서비스 기동까지 마친다. 기본값 false (실습 대상이므로 수동)"
  type        = bool
  default     = false
}

variable "keepalived_use_unicast" {
  description = "preinstall_keepalived_config = true 일 때 유니캐스트 설정을 쓸지. DKU 환경은 멀티캐스트가 동작하므로 기본 false"
  type        = bool
  default     = false
}
