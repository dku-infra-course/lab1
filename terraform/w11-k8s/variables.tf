variable "api_url" {
  description = "CloudStack API 엔드포인트"
  type        = string
  default     = "https://dku.kloud.zone/client/api"
}

variable "api_key" {
  description = "CloudStack API Key. 우측 상단 프로필 > 사용자 상세 > API 키 생성"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "CloudStack Secret Key"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "클러스터 이름 접미사(학번). 클러스터 이름은 k8s-<name_prefix>"
  type        = string
}

variable "zone_name" {
  description = "클러스터를 만들 존 이름"
  type        = string
  default     = "DKU"
}

variable "kubernetes_version_name" {
  description = "콘솔에 등록된 Kubernetes 버전 이름 (Calico 포함). 11주차 가이드의 값과 같다"
  type        = string
  default     = "Kubernetes_1.32.5_with_Calico"
}

variable "service_offering_name" {
  description = "노드 컴퓨트 오퍼링 이름. 기본 Medium(2 vCPU / 4GB). 학생 계정은 Medium 3대(6 vCPU / 12GB)까지 동시에 쓸 수 있고, 클러스터 노드 2대가 4 vCPU / 8GiB를 쓰고 2 vCPU / 4GiB가 남는다"
  type        = string
  default     = "Medium"
}

variable "worker_size" {
  description = "워커 노드 수. 1로 둔다. control 1 + worker 1 = Medium 2대, 여기에 1대를 더하면 한도(Medium 3대)를 다 쓰기 때문에, 늘리면 한도를 넘어 생성이 실패하거나 멈춘다"
  type        = number
  default     = 1
}

variable "control_nodes_size" {
  description = "컨트롤 노드 수. 실습용 단일 컨트롤 플레인이라 1로 둔다"
  type        = number
  default     = 1
}

variable "shared_network_id" {
  description = "클러스터를 올릴 Shared Network 의 ID. 콘솔 Networks 상세 화면에서 확인한다. 비워 두면 격리망이 새로 만들어져 클러스터가 Starting 에서 멈추므로 빈 값은 허용하지 않는다"
  type        = string

  validation {
    condition     = length(trimspace(var.shared_network_id)) > 0
    error_message = "shared_network_id 는 비울 수 없다. 콘솔 Networks 에서 Shared Network 의 ID 를 복사해 넣는다."
  }
}

variable "node_root_disk_gb" {
  description = "노드 루트 디스크(GB)"
  type        = number
  default     = 20
}

variable "ssh_public_key_path" {
  description = "노드에 넣을 SSH 공개키 파일 경로. 이 키로 컨트롤 노드에 cloud 계정으로 접속한다. 없으면 ssh-keygen -t ed25519 로 만든다"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_path))
    error_message = "공개키 파일이 없다. ssh-keygen -t ed25519 로 만든 뒤 경로를 확인한다(기본 ~/.ssh/id_ed25519.pub)."
  }
}
