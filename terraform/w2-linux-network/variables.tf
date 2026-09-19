# ---------------------------------------------------------------------------
# 접속 정보 (자격증명은 terraform.tfvars 에 채운다. api_key/secret_key/name_prefix 는 필수다)
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
  description = "컴퓨트 오퍼링 이름. 확인됨(2026-08-23): Small(1core/2GB) · Medium(2core/4GB) · Large(4core/8GB) · XLarge(8core/16GB) · Custom. W2 가이드가 명시하는 값은 Medium(기본값). 연습문제 ③이 이 표기값과 lscpu 실측값을 비교하므로 실제로 맞아야 한다"
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
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호. 실습 관례값은 ubuntu"
  type        = string
  default     = "ubuntu"
}

variable "ssh_keypair_name" {
  description = "CloudStack 에 등록된 SSH 키쌍 이름. 빈 문자열이면 비밀번호 로그인만 사용한다"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# W2: 기존 공용 Shared Network 를 그대로 사용한다 (새 네트워크를 만들지 않는다)
#
# provider 0.5.0 에는 network 을 이름으로 찾는 data source 가 없다.
# 그래서 네트워크 ID 를 변수로 받는다. ID 확인 방법은 README 3절을 참고한다.
# ---------------------------------------------------------------------------

variable "shared_network_id" {
  description = "붙일 공용 Shared Network 의 UUID. 콘솔 [네트워크] 목록에서 확인한다"
  type        = string
}

variable "shared_network_name" {
  description = "공용 Shared Network 이름. 문서·출력용으로만 쓴다. 확인됨(2026-08-23): \"Shared Network\""
  type        = string
  default     = "Shared Network"
}

variable "create_web02" {
  description = "web02 를 함께 만들 것인지. 가이드 6단계(두 대 사이 사설 IP 통신)를 확인하려면 true"
  type        = bool
  default     = false
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init 으로 ubuntu 계정에 직접 추가할 공개키 목록. 콘솔 키페어 주입이 안 되는 이 플랫폼에서 자동 검증용 접속을 만들 때만 쓴다. 기본값은 비워 둔다(학생 실습에는 영향 없음)"
  type        = list(string)
  default     = []
}
