# Terraform 사용 안내

Terraform을 처음 써보는 사람을 위한 안내다. 각 주차 폴더(`w1-environment/` ~ `w5-cache/`)의 구체적인 변수·순서는 그 폴더의 `README.md`를 따르고, 여기서는 공통으로 알아야 할 개념·설치·명령·주의사항만 다룬다.

## Terraform이 무엇이고 왜 쓰는가

Solid Cloud 콘솔에서 VM을 하나씩 클릭해 만드는 대신, "어떤 VM을 몇 대, 어떤 네트워크에 만든다"를 텍스트 파일(`.tf`)로 적어 두고 그 파일로 실제 자원을 만드는 도구다.

- **재현 가능하다.** 같은 파일을 다시 실행하면 같은 환경이 다시 만들어진다. VM을 잘못 건드려도 지우고 다시 만들면 된다.
- **삭제가 쉽다.** 콘솔에서 VM·네트워크·방화벽 규칙을 하나씩 찾아 지우는 대신, 명령 하나로 그 파일이 만든 것만 정확히 지운다.
- **변경 전에 미리 본다.** 실제로 자원을 만들거나 지우기 전에 "무엇이 바뀔지"를 먼저 보여준다.

## 핵심 개념 3가지

| 용어 | 의미 |
|---|---|
| Provider | 어떤 클라우드를 다룰지 정하는 플러그인. 이 저장소는 CloudStack provider를 쓴다(`provider.tf`) |
| Resource | 실제로 만들 대상 하나(VM 한 대, 네트워크 하나 등). `.tf` 파일 안의 `resource "..." "..." { ... }` 블록 하나가 하나의 자원이다 |
| State(상태 파일, `terraform.tfstate`) | Terraform이 "지금까지 무엇을 만들었는지" 기록해 두는 파일. 이 파일이 있어야 다음에 무엇을 지우고 무엇을 바꿔야 하는지 안다. **절대 커밋하지 않는다**(아래 참고) |

## 설치

### Linux (Ubuntu/Debian 계열)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform -version
```

설치 절차가 바뀌었으면 공식 문서(Install Terraform, HashiCorp)를 확인한다.

### Windows

1. [HashiCorp 공식 다운로드 페이지](https://developer.hashicorp.com/terraform/install)에서 Windows용 zip을 받는다.
2. 압축을 풀어 나온 `terraform.exe`를 아무 폴더(예: `C:\terraform\`)에 둔다.
3. 그 폴더를 PATH 환경 변수에 추가한다: 시작 메뉴 → "환경 변수 편집" → 시스템 변수의 `Path` → 새로 만들기 → 그 폴더 경로 추가.
4. PowerShell(또는 명령 프롬프트)을 새로 열고 확인한다.

```powershell
terraform -version
```

또는 [Chocolatey](https://chocolatey.org/)가 설치되어 있으면 한 줄로 된다.

```powershell
choco install terraform
```

**Windows에서 SSH 접속은 별도 준비가 필요하다.** Windows 10/11은 OpenSSH 클라이언트가 기본 포함이라 PowerShell에서 `ssh ubuntu@10.0.X.X`가 바로 되지만, 안 되면 "설정 → 앱 → 선택적 기능 → OpenSSH 클라이언트"를 켠다. 또는 WSL(Windows Subsystem for Linux)을 설치해 그 안에서 Linux와 동일하게 진행해도 된다.

## 이 저장소에서의 실행 순서

각 주차 폴더로 들어가서 진행한다. 예시는 `w1-environment/`.

```bash
cd terraform/w1-environment

cp terraform.tfvars.example terraform.tfvars   # api_key, secret_key, shared_network_id 등을 본인 값으로 채운다
terraform init      # provider 플러그인을 내려받는다(폴더마다 한 번)
terraform plan      # 무엇을 만들지 미리 확인한다
terraform apply     # 확인 후 y 입력, 실제로 만든다

# --- 실습 진행 ---

terraform destroy   # 실습이 끝나면 반드시 지운다
```

## 대표 명령 정리

| 명령 | 하는 일 | 언제 쓰나 |
|---|---|---|
| `terraform init` | 이 폴더에서 쓸 provider 플러그인을 내려받고 초기화한다 | 폴더를 처음 쓸 때, 또는 `provider.tf`를 바꿨을 때 한 번 |
| `terraform plan` | 지금 상태와 코드를 비교해 "무엇이 추가/변경/삭제될지" 미리 보여준다. **아직 아무것도 만들지 않는다** | `apply`·`destroy` 전에 항상 |
| `terraform apply` | `plan` 결과를 보여주고 `yes`를 입력하면 실제로 자원을 만든다 | 환경을 만들 때 |
| `terraform destroy` | 이 폴더가 만든 자원을 전부 지운다 | 실습이 끝난 뒤 항상 |
| `terraform validate` | `.tf` 파일 문법만 검사한다(클라우드에 접속하지 않음) | 코드를 고친 직후 |
| `terraform fmt` | `.tf` 파일 들여쓰기·형식을 정리한다 | 코드를 고친 직후(선택) |
| `terraform output` | `outputs.tf`에 정의된 값(VM IP 등)을 다시 출력한다 | `apply` 후 IP를 다시 확인하고 싶을 때 |
| `terraform state list` | 지금 이 폴더가 관리 중인 자원 목록을 보여준다 | 뭐가 만들어져 있는지 헷갈릴 때 |

`plan`과 `apply`는 항상 짝이다. `plan` 없이 바로 `apply`해도 동작은 하지만(내부적으로 plan을 한번 하고 보여준다), 결과를 확인하는 습관을 들이는 게 좋다.

## 실습 전후로 반드시 지켜야 하는 것: destroy

Solid Cloud는 학교 전체가 나눠 쓰는 자원이다. VM을 켜 둔 채로 두면:

- 다른 학생·다른 주차 실습에 배정될 자원이 줄어든다.
- 같은 주차를 다시 연습하려 할 때, 이미 자원을 다 쓴 상태라 새로 만들 수 없는 경우가 생긴다.
- 기존 실습 가이드도 "주차마다 VM을 정리(Destroy)한다"를 원칙으로 한다(6주차 실습 참고).

그래서 순서는 항상 **실습 시작 전에 이전 것이 남아있지 않은지 확인 → 이번 주차 것을 apply → 실습 → destroy**다.

```bash
# 실습을 시작하기 전, 혹시 지난 번 자원이 남아 있는지 확인
terraform state list

# 아무것도 안 나오면 깨끗한 상태. 뭔가 나오면 지우고 시작한다
terraform destroy
```

`destroy` 전에 `plan`처럼 무엇이 지워질지 먼저 보여주고 `yes`를 물어본다. 실수로 다른 걸 지우는 경우를 막기 위한 장치이니, 목록을 한 번 읽고 진행한다.

## 드리프트(Configuration Drift)

**드리프트**란 Terraform 코드(state 파일에 기록된 "만들었다고 알고 있는 상태")와 클라우드에 실제로 있는 상태가 어긋나는 것을 말한다. 흔히 생기는 경우:

- 콘솔에서 직접 VM을 끄거나 지웠다(Terraform은 그 사실을 모른다).
- VM을 재부팅했더니 DHCP로 사설 IP가 바뀌었다.
- 같은 실습 환경을 다른 사람(조교 등)이 콘솔에서 손으로 정리했다.
- `terraform apply`가 중간에 실패해서 일부만 만들어진 채로 남았다.

**증상**: `terraform plan`을 실행했는데 아무것도 코드를 안 고쳤음에도 "이 자원을 다시 만들겠다" 또는 "이 값이 다르다"는 변경 사항이 뜬다.

**대응 순서**:

1. 먼저 `terraform plan`으로 무엇이 다른지 확인한다. 절대 내용을 안 보고 `apply`를 누르지 않는다.
2. 클라우드 쪽 실제 상태가 맞고 코드가 오래된 경우라면, 최신 버전의 Terraform은 `terraform plan -refresh-only`로 state만 실제 상태에 맞춰 갱신할 수 있다(예전 버전은 `terraform refresh`).
3. 자원이 콘솔에서 이미 지워졌는데 state에는 남아 있다면, `terraform apply`가 그걸 다시 만들려고 한다. 다시 만들 필요가 없으면 `terraform state rm <자원 이름>`으로 state에서만 지운다.
4. 실습용 환경은 대부분 이 정도로 복잡하게 따라가기보다, **`terraform destroy`로 깨끗하게 지우고 `terraform apply`로 새로 만드는 것이 가장 안전하고 빠르다.** 실습 환경은 데이터를 보존할 이유가 없기 때문이다.

## 자격증명 주의

- `terraform.tfvars`(실제 `api_key`·`secret_key`가 들어간 파일)와 `terraform.tfstate`(자원 상세 정보가 들어간 파일)는 절대 커밋하지 않는다. 각 폴더의 `.gitignore`와 저장소 루트의 `.gitignore`에 이미 패턴이 들어 있지만, 최종 확인은 커밋하는 사람 책임이다.
- 커밋 전에 항상 `git status`로 무엇이 올라가는지 확인한다.
- API 키를 실수로 커밋했다면 되돌리는 것으로 끝나지 않는다. Solid Cloud 콘솔에서 그 키를 즉시 폐기하고 새로 발급한다.

## 주차별 폴더

| 폴더 | 만드는 것 |
|---|---|
| `w1-environment/` | 1주차: 격리 네트워크 + VM 1대(환경 준비) |
| `w2-linux-network/` | 2주차: 기본 Shared Network에 VM 1대(Apache) |
| `w3-ha-keepalived/` | 3주차: 격리 네트워크 + VM 2대(Keepalived VIP 이중화) |
| `w4-loadbalancer/` | 4주차: Shared Network에 웹서버 2대 + LB 1대(Nginx 로드밸런싱), 선택으로 IPVS 심화 3대 추가 |
| `w5-cache/` | 5주차: Shared Network에 웹서버 1대 + 캐시서버 1대(Redis·Nginx·Squid) |

각 폴더 안의 `README.md`에 그 주차의 변수 목록·전제 조건·실행 예시가 자세히 있다.
