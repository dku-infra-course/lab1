# ---------------------------------------------------------------------------
# 접속 정보 (자격증명은 terraform.tfvars 또는 TF_VAR_* 환경변수로 받는다)
# ---------------------------------------------------------------------------

variable "api_url" {
  description = "CloudStack API 엔드포인트. 콘솔 [계정] > [API 키] 화면에서 확인한다 (기본값 검증됨)"
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
  description = "VM 템플릿 이름. Ubuntu_24.04(Featured) / Ubuntu_22.04(Community) / Ubuntu_24.04_VSCode(Web IDE)"
  type        = string
  default     = "Ubuntu_24.04"
}

variable "template_filter" {
  description = "템플릿 검색 범위. Ubuntu_24.04 는 featured, Ubuntu_22.04 는 community"
  type        = string
  default     = "featured"
}

variable "service_offering_name" {
  description = "컴퓨트 오퍼링 이름. 확인됨(2026-08-23): Small(1core/2GB) · Medium(2core/4GB) · Large(4core/8GB) · XLarge(8core/16GB) · Custom. W1 가이드 Part D · 5단계가 명시하는 값은 Medium(기본값)"
  type        = string
  default     = "Medium"
}

variable "root_disk_size" {
  description = "루트 디스크 크기 (GB). 템플릿 기본값 20"
  type        = number
  default     = 20
}

variable "name_prefix" {
  description = "학번이나 강사 식별자. VM 이름은 가이드 표기(web01-{학번})에 맞춰 web01-<name_prefix> 형태로 만들어진다. 네트워크 등 다른 리소스 이름에는 그대로 접두사로 쓴다"
  type        = string
  default     = "w1env"
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호. 실습 관례값은 ubuntu 이며 검증 목적에만 쓴다"
  type        = string
  default     = "ubuntu"
}

variable "ssh_keypair_name" {
  description = "CloudStack 에 등록된 SSH 키쌍 이름. 빈 문자열이면 비밀번호 로그인만 사용한다"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# W1: Isolated Network 를 새로 만든다 (실습 가이드 3단계에 대응)
# ---------------------------------------------------------------------------

variable "network_cidr" {
  description = "격리 네트워크 CIDR. 3주차 이후 설정을 그대로 쓰기 위해 192.168.0.0/24 를 권장"
  type        = string
  default     = "192.168.0.0/24"
}

variable "network_offering" {
  description = "격리 네트워크 오퍼링. Source NAT / 포트포워딩 / 방화벽이 포함된 기본 오퍼링"
  type        = string
  default     = "DefaultIsolatedNetworkOfferingWithSourceNatService"
}

variable "web01_ip" {
  description = "web01 사설 IP (실습 관례값)"
  type        = string
  default     = "192.168.0.10"
}

variable "web02_ip" {
  description = "web02 사설 IP (실습 관례값). create_web02 = true 일 때만 사용"
  type        = string
  default     = "192.168.0.11"
}

variable "create_web02" {
  description = "web02 를 함께 만들 것인지. W1 가이드의 필수 구간은 1대만으로 충분하다"
  type        = bool
  default     = false
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
  description = "SSH 인바운드를 허용할 Source CIDR. 가이드는 VPN 대역으로 한정하라고 안내한다. 확인됨(2026-08-23): VPN 대역은 10.8.0.0/24(넷마스크 255.255.255.0). 기본값은 실습에서 직접 좁혀 보도록 0.0.0.0/0으로 열어 둔다"
  type        = string
  default     = "0.0.0.0/0"
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init 으로 ubuntu 계정에 직접 추가할 공개키 목록. 콘솔 키페어 주입이 안 되는 이 플랫폼에서 자동 검증용 접속을 만들 때만 쓴다. 기본값은 비워 둔다(학생 실습에는 영향 없음)"
  type        = list(string)
  default     = []
}
