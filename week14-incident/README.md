# 14주차 실습 코드: 장애 대응과 복구 (실측 전)

## settings.json 규칙 문법
`Bash(kubectl get *)` 형식이다(끝의 `:*`와 같은 뜻). 평가 순서는 deny, ask, allow. 출처: https://code.claude.com/docs/en/permissions (research_2026-11-13). CLAUDE.md 자동 읽기는 lab-verifier가 확인한다. `.claude/settings.json`으로 복사해 쓴다.

## 파일
- `helm/podinfo-frontend-ha.yaml` topologySpreadConstraints와 PDB를 더한 frontend values
- `terraform-db/` DB VM 1대 (복사 후 terraform.tfvars.example을 채운다)
- `backup/` seed.sql, backup.sh, restore.sh (본인 PC에서 실행)
- `postmortem/` TEMPLATE.md, scenario-report-TEMPLATE.md
- `aiops/` rbac-readonly.yaml, rbac-remediate.yaml, make-kubeconfig.sh, CLAUDE.md, settings.json, inject-bad-image.sh
- `aiops/alt/` D3 대안(Claude Code 유료 플랜 없음): AGENTS.md, opencode.example.json, codex.example.toml, codex-kubectl.rules.example, gemini-policy.example.toml, README.md

## 명령 순서
```bash
cd ~/lab1/week14-incident
# A 개선과 재측정 (13주차 terraform 디렉터리에서 worker_count를 2로)
cd ~/lab1/week13-sre/terraform && terraform apply -var worker_count=2 && cd -
helm repo update && helm upgrade frontend podinfo/podinfo -n sre-lab -f helm/podinfo-frontend-ha.yaml
~/lab1/week13-sre/scripts/mark.sh 주입 && ~/lab1/week13-sre/scripts/fault.sh enable   # 재주입

# B 백업 복원
cd terraform-db && cp terraform.tfvars.example terraform.tfvars && terraform init && terraform apply
DB=$(terraform output -raw db_ip); cd ..
scp backup/seed.sql ubuntu@$DB:~/ && ssh ubuntu@$DB 'cloud-init status --wait; sudo mysql < seed.sql'
./backup/backup.sh $DB
terraform -chdir=terraform-db destroy -auto-approve && terraform -chdir=terraform-db apply -auto-approve
./backup/restore.sh $(terraform -chdir=terraform-db output -raw db_ip) ~/dr-backup/dku-<시각>.sql.gz

# D AIOps
kubectl apply -f aiops/rbac-readonly.yaml
./aiops/make-kubeconfig.sh ai-reader 2h
KUBECONFIG=~/.kube/ai-reader.config kubectl auth can-i delete pods -n sre-lab   # no
```
시크릿(tfvars, tfstate, kubeconfig, 토큰)은 저장소에 올리지 않는다.
