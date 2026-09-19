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
  description = "컴퓨트 오퍼링 이름. 확인됨(2026-08-23): Small(1core/2GB) · Medium(2core/4GB) · Large(4core/8GB) · XLarge(8core/16GB) · Custom. W5 가이드가 명시하는 값은 Medium(기본값)"
  type        = string
  default     = "Medium"
}

variable "root_disk_size" {
  description = "루트 디스크 크기 (GB)"
  type        = number
  default     = 20
}

variable "name_prefix" {
  description = "학번이나 강사 식별자. VM 이름은 가이드 표기(webserver-{학번}, cache-{학번})에 맞춰 webserver-<name_prefix> 형태로 만들어진다"
  type        = string
  default     = "w5cache"
}

variable "vm_password" {
  description = "ubuntu 계정 비밀번호"
  type        = string
  default     = "ubuntu"
}

variable "extra_ssh_authorized_keys" {
  description = "cloud-init 으로 ubuntu 계정에 직접 추가할 공개키 목록. 콘솔 키페어 주입이 안 되는 이 플랫폼에서 자동 검증용 접속을 만들 때만 쓴다. 기본값은 비워 둔다(학생 실습에는 영향 없음)"
  type        = list(string)
  default     = []
}

variable "ssh_keypair_name" {
  description = "CloudStack 에 등록된 SSH 키쌍 이름. 빈 문자열이면 비밀번호 로그인만 사용한다"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# W5: 기존 공용 Shared Network 를 그대로 사용한다 (새 네트워크를 만들지 않는다)
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
# W5: 어디까지 미리 만들어 둘지
#
# 기본값은 "패키지 설치까지만" 이다.
# 앱 코드 배치, Redis 보안 설정, Nginx/Squid 캐시 설정은 모두 실습의 학습 대상이다.
# ---------------------------------------------------------------------------

variable "preinstall_app_code" {
  description = "true 면 webserver 에 app.py 와 backend-app systemd 유닛까지 배치하고 기동한다. 기본값 false"
  type        = bool
  default     = false
}

variable "preinstall_cache_config" {
  description = "true 면 cache 에 Nginx 캐시 존·프록시 설정과 Squid cache_dir 까지 배치한다. 기본값 false"
  type        = bool
  default     = false
}

variable "redis_password" {
  description = "Redis requirepass 값. 빈 문자열이면 requirepass 를 설정하지 않는다(실습에서 직접 설정). 값을 넣으면 preinstall_app_code = true 일 때 앱에도 같은 값이 전달된다"
  type        = string
  default     = ""
  sensitive   = true
}
