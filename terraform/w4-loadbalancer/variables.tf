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
  description = "컴퓨트 오퍼링 이름. 확인됨(2026-08-23): Small(1core/2GB) · Medium(2core/4GB) · Large(4core/8GB) · XLarge(8core/16GB) · Custom. W4 가이드가 명시하는 값은 Medium(기본값, web01·web02·lb 동일)"
  type        = string
  default     = "Medium"
}

variable "root_disk_size" {
  description = "루트 디스크 크기 (GB)"
  type        = number
  default     = 20
}

variable "name_prefix" {
  description = "학번이나 강사 식별자. VM 이름은 가이드 표기(web01-{학번}, lb-{학번})에 맞춰 web01-<name_prefix> 형태로 만들어진다. IPVS 랩(B3)도 동일하게 ipvs-web01-<name_prefix> 형태"
  type        = string
  default     = "w4lb"
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

# ---------------------------------------------------------------------------
# W4: 기존 공용 Shared Network 를 그대로 사용한다 (새 네트워크를 만들지 않는다)
#
# provider 0.5.0 에는 network 을 이름으로 찾는 data source 가 없어서 ID 를 변수로 받는다.
# ---------------------------------------------------------------------------

variable "shared_network_id" {
  description = "붙일 공용 Shared Network 의 UUID. 콘솔 [네트워크] 상세 화면에서 확인한다"
  type        = string
}

variable "shared_network_name" {
  description = "공용 Shared Network 이름. 문서·출력용. 확인됨(2026-08-23): \"Shared Network\""
  type        = string
  default     = "Shared Network"
}

# ---------------------------------------------------------------------------
# W4: 백엔드 페이지 문구와 사전 구성 범위
# ---------------------------------------------------------------------------

variable "web01_page_label" {
  description = "web01 백엔드 구분 페이지 문구"
  type        = string
  default     = "Web Server 01"
}

variable "web02_page_label" {
  description = "web02 백엔드 구분 페이지 문구. 리버스 프록시 /admin 실습에서는 Administrator Page 로 바꾼다"
  type        = string
  default     = "Web Server 02"
}

variable "preinstall_packages" {
  description = "true 면 세 VM에 apache2·nginx·curl 을 설치만 한다. 기본값(false)은 패키지조차 설치하지 않은 순정 Ubuntu다. 학생이 콘솔로 직접 만드는 VM과 조건을 맞추기 위한 것이다"
  type        = bool
  default     = false
}

variable "preinstall_lb_config" {
  description = "true 면 패키지 설치까지 포함해서 lb 에 nginx upstream 설정까지 배치한다. 기본값 false (LB 설정은 실습 대상이므로 설치만 한다)"
  type        = bool
  default     = false
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init 으로 ubuntu 계정에 직접 추가할 공개키 목록. 콘솔 키페어 주입이 안 되는 이 플랫폼에서 자동 검증용 접속을 만들 때만 쓴다. 기본값은 비워 둔다(학생 실습에는 영향 없음)"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# W4 선택·심화 B3(IPVS/LVS): 이번 주 본 실습(Shared Network 3대)과 완전히 별개인
# 격리 네트워크 + VM 3대(web01·web02·director). enable_ipvs_lab = true 일 때만
# 만들어진다. 기본값 false면 아래 변수는 전부 무시된다.
# ---------------------------------------------------------------------------

variable "enable_ipvs_lab" {
  description = "true 면 B3(IPVS/LVS) 전용 격리 네트워크와 VM 3대를 추가로 만든다. 기본값 false: B3는 선택·심화이고, 학생은 클라우드 쿼터가 정해져 있어 본 실습(3대)에 필요 없는 VM을 기본으로 더 만들지 않는다. 본 실습(web01·web02·lb, Shared Network)에는 영향 없음"
  type        = bool
  default     = false
}

variable "ipvs_service_offering_name" {
  description = "IPVS 랩 3대의 컴퓨트 오퍼링. 기본값 Small: B3는 Web IDE를 쓰지 않고 IPVS/LVS 자체도 가벼운 작업이라 Medium이 필요 없다(가이드도 B3에 별도 오퍼링을 명시하지 않는다). 쿼터를 아끼기 위한 기본값"
  type        = string
  default     = "Small"
}

variable "ipvs_network_cidr" {
  description = "IPVS 랩 격리 네트워크 CIDR. 3주차와 같은 값을 권장(가이드의 VIP 192.168.0.100과 맞아야 한다)"
  type        = string
  default     = "192.168.0.0/24"
}

variable "ipvs_web01_ip" {
  description = "IPVS 랩 web01 사설 IP"
  type        = string
  default     = "192.168.0.10"
}

variable "ipvs_web02_ip" {
  description = "IPVS 랩 web02 사설 IP"
  type        = string
  default     = "192.168.0.11"
}

variable "ipvs_director_ip" {
  description = "IPVS/LVS 를 실행할 VM(디렉터)의 사설 IP"
  type        = string
  default     = "192.168.0.20"
}

variable "ipvs_ssh_public_port_web01" {
  description = "IPVS 랩 web01 SSH 포트포워딩 공인 포트"
  type        = number
  default     = 2201
}

variable "ipvs_ssh_public_port_web02" {
  description = "IPVS 랩 web02 SSH 포트포워딩 공인 포트"
  type        = number
  default     = 2202
}

variable "ipvs_ssh_public_port_director" {
  description = "IPVS 랩 디렉터 VM SSH 포트포워딩 공인 포트"
  type        = number
  default     = 2203
}

variable "ssh_allowed_cidr" {
  description = "IPVS 랩 격리 네트워크의 SSH 인바운드를 허용할 Source CIDR. VPN 대역은 10.8.0.0/24로 확인됨. 기본값은 실습에서 직접 좁혀 보도록 0.0.0.0/0으로 열어 둔다"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ipvs_preinstall_packages" {
  description = "true 면 IPVS 랩의 web01·web02에 Apache를 설치만 한다(본 실습의 preinstall_packages와 같은 개념). 기본값 false, 학생이 콘솔로 만드는 VM과 조건을 맞춘다"
  type        = bool
  default     = false
}
