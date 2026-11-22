# 14주차 실습 코드: 장애 대응과 복구 (실측 전)

## settings.json 규칙 문법
`Bash(kubectl get *)` 형식이다(끝의 `:*`와 같은 뜻). 평가 순서는 deny, ask, allow. 출처: https://code.claude.com/docs/en/permissions (research_2026-11-13). CLAUDE.md 자동 읽기는 lab-verifier가 확인한다. `.claude/settings.json`으로 복사해 쓴다.

## 파일
- `helm/podinfo-frontend-ha.yaml` topologySpreadConstraints와 PDB를 더한 frontend values
- `terraform-db/` DB VM 1대 (복사 후 terraform.tfvars.example을 채운다)
- `backup/` seed.sql, backup.sh, restore.sh (본인 PC에서 실행. DB VM에 SSH가 되는 곳이고 PC의 사본이 오프사이트 사본이다)
- `postmortem/` TEMPLATE.md, scenario-report-TEMPLATE.md
- `aiops/` rbac-readonly.yaml, rbac-remediate.yaml, make-kubeconfig.sh, CLAUDE.md, settings.json, inject-bad-image.sh (kubeconfig 생성과 inject는 컨트롤 노드, Claude Code와 settings.json은 본인 PC)
- `aiops/alt/` D3 대안(Claude Code 유료 플랜 없음): AGENTS.md, opencode.example.json, codex.example.toml, codex-kubectl.rules.example, gemini-policy.example.toml, README.md

## 작업 위치
- **컨트롤 노드**(`ssh cloud@<컨트롤 노드 IP>`): `kubectl`, `helm`, `mark.sh`, `fault.sh`, `make-kubeconfig.sh`, `inject-bad-image.sh`. 저장소는 tar로 받는다(컨트롤 노드에는 `git`이 없다).
  `mkdir -p ~/lab1 && curl -fsSL https://github.com/dku-infra-course/lab1/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C ~/lab1`
- **본인 PC**: `terraform`(11주차 클러스터 코드 `terraform/w11-k8s`의 `worker_size`, DB VM `terraform-db`), `backup.sh`, `restore.sh`, Claude Code. PC에서 `git clone` 또는 `git pull`로 `~/lab1`을 둔다.
- Claude Code는 PC에서 실행하고, 컨트롤 노드에서 만든 `ai-reader.config`만 `scp`로 PC에 복사한다(권한 600).

## 명령 순서
```bash
# A 개선과 재측정: 본인 PC에서 11주차 클러스터 코드의 worker_size를 2로
cd ~/lab1/terraform/w11-k8s && terraform plan -var worker_size=2 && terraform apply -var worker_size=2
# 이후는 컨트롤 노드에서
cd ~/lab1/week14-incident
helm repo update && helm upgrade frontend podinfo/podinfo -n sre-lab -f helm/podinfo-frontend-ha.yaml
~/lab1/week13-sre/scripts/mark.sh 주입 && ~/lab1/week13-sre/scripts/fault.sh enable   # 재주입

# B 백업 복원 (본인 PC에서)
cd ~/lab1/week14-incident/terraform-db && cp terraform.tfvars.example terraform.tfvars && terraform init && terraform apply
DB=$(terraform output -raw db_ip); cd ..
scp backup/seed.sql ubuntu@$DB:~/ && ssh ubuntu@$DB 'cloud-init status --wait; sudo mysql < seed.sql'
./backup/backup.sh $DB
terraform -chdir=terraform-db destroy -auto-approve && terraform -chdir=terraform-db apply -auto-approve
./backup/restore.sh $(terraform -chdir=terraform-db output -raw db_ip) ~/dr-backup/dku-<시각>.sql.gz

# D AIOps (컨트롤 노드에서 만들고 PC로 복사)
kubectl apply -f aiops/rbac-readonly.yaml
./aiops/make-kubeconfig.sh ai-reader 2h
KUBECONFIG=~/.kube/ai-reader.config kubectl auth can-i delete pods -n sre-lab   # no
# 본인 PC에서: scp cloud@<컨트롤 노드 IP>:~/.kube/ai-reader.config ~/.kube/ai-reader.config && chmod 600 ~/.kube/ai-reader.config
```
시크릿(tfvars, tfstate, kubeconfig, 토큰)은 저장소에 올리지 않는다.
