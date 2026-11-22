# D3 대안: Claude Code 유료 플랜이 없을 때

예시 파일은 `aiops/CLAUDE.md`와 `aiops/settings.json`이다. 이 폴더는 같은 하네스(지침 · 읽기 전용 kubeconfig · 도구 제한 · 사람 승인)를 다른 도구에 옮기는 예시다. 모두 2026-11-22 공식 문서 기준이며 실측 전이다(lab-verifier 미실행). 문법이 바뀌면 공식 문서가 우선한다.

## 공통
- 지침: `AGENTS.md`(이 폴더)를 작업 폴더에 복사한다. `<노드IP>`는 실제 값으로 바꾼다.
- 계정: 읽기 전용 `~/.kube/ai-reader.config`만 쓴다. `KUBECONFIG=~/.kube/ai-reader.config <도구>`로 시작한다.
- 변경 명령(`rollout undo` 등)은 도구가 아니라 사람이 ai-operator로 실행한다.
- 도구 제한은 명령 문자열 규칙이라 우회될 수 있다. 서버 RBAC가 기본 방어선이다.

## OpenCode (오픈소스, MIT)
- 설치: `curl -fsSL https://opencode.ai/v2/install | bash` 또는 `npm install -g @opencode/cli`. 출처 https://opencode.ai/docs/
- 지침: `AGENTS.md`. AGENTS.md가 없는 폴더에서는 `CLAUDE.md`를 대신 읽는다. 출처 https://opencode.ai/docs/instructions/
- 권한: `opencode.example.json`을 작업 폴더의 `opencode.json`(또는 `opencode.jsonc`)으로 복사한다. V2 문법이다(`permissions` 배열, `action` `resource` `effect`, 마지막으로 맞는 규칙이 이긴다). 출처 https://opencode.ai/docs/permissions/
- V1(`opencode-ai` 패키지)은 필드 이름이 다르다(`permission`, `bash`). 어느 버전이 깔렸는지 `opencode --version`으로 보고 공식 문서를 확인한다.
- 실행: `opencode run "프롬프트"`. 출처 https://opencode.ai/docs/cli
- 모델: 로컬 모델(Ollama를 켜 두면 자동 탐지)이나 본인 공급자 키. 유료 구독(OpenCode Go 월 10달러 표기)은 선택이다. 가격은 변동 가능, 수업 시점 확인.
- 미확인: `opencode run`에서 `ask` 규칙이 어떻게 처리되는지(공식 문서 확인). 환경 변수 읽기를 막는 설정. 작은 로컬 모델의 도구 호출 품질.

## Codex CLI (오픈소스, Apache-2.0)
- 설치: `npm install -g @openai/codex` 또는 `brew install --cask codex`. 출처 https://github.com/openai/codex
- 지침: `AGENTS.md`(전역 `~/.codex/AGENTS.md`, 프로젝트 루트부터 현재 폴더까지). 출처 https://learn.chatgpt.com/docs/agent-configuration/agents-md
- 권한: `codex.example.toml`을 `~/.codex/config.toml`에 반영한다(`sandbox_mode = "read-only"`, `approval_policy = "on-request"`). 명령별 allow/prompt/forbidden은 `codex-kubectl.rules.example`을 `~/.codex/rules/default.rules`로 복사한다(문서에 experimental 표기). 읽기 전용 샌드박스는 네트워크가 꺼져 있으므로 kubectl은 규칙의 allow나 승인으로 샌드박스 밖에서 실행된다.
- 실행: `codex exec "프롬프트"`(기본 읽기 전용, Git 저장소 필요). 출처 https://learn.chatgpt.com/docs/non-interactive-mode
- 계정: ChatGPT 계정(Plus 이상 표기) 로그인 또는 API 키(종량). 문서상 CLI는 무료 플랜 항목이 아니다. 변동 가능, 수업 시점 확인.
- 미확인: kubeconfig와 tfvars 읽기를 막는 permissions 프로필 문법(공식 문서 확인). `.rules`가 `read-only` 안의 읽기 명령에 어떻게 적용되는지는 실측 전.

## Gemini CLI (오픈소스, Apache-2.0)
- 설치: `npm install -g @google/gemini-cli` 또는 `brew install gemini-cli`. 출처 https://github.com/google-gemini/gemini-cli
- 지침: `GEMINI.md`. `settings.json`의 `context.fileName`에 `AGENTS.md`를 넣으면 읽는다. 출처 https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md
- 권한: `gemini-policy.example.toml`을 `~/.gemini/policies/`에 복사한다(policy engine). 승인 모드는 `--approval-mode`(`default` `auto_edit` `yolo` `plan`). 프로젝트 정책 폴더는 문서상 현재 동작하지 않는다.
- 실행: `gemini -p "프롬프트"`(비대화형에서 ask_user는 deny).
- 계정: README에 따르면 개인 무료 이용과 Google AI Pro/Ultra는 2026-06-18에 Antigravity CLI(`agy`)로 이전했다. 이 도구는 Gemini Code Assist Standard/Enterprise 또는 유료 API 키용이다. 무료 대안으로는 맞지 않을 수 있다. Antigravity CLI의 무료 조건과 권한 문법은 미확인.
- 미확인: read_file 거부 규칙의 `argsPattern` 키 이름(공식 문서 확인).

## 웹 챗에 붙여넣기 (무료, 최후 수단)
- 사람이 읽기 명령(`kubectl get pods` · `describe` · `logs --tail=50`)을 실행하고 출력만 붙인다.
- 붙이기 전에 마스킹한다: IP와 호스트 이름은 `<IP>`로, 토큰과 키 · 개인 정보는 삭제한다. Secret은 조회하지 않는다.
- `AGENTS.md`의 진행 순서(관측 → 가설 → 증거 → 제안)를 첫 메시지에 붙인다.
