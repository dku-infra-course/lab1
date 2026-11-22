#!/usr/bin/env bash
# 실측 전
# 본인 PC에서 실행한다. DB VM에서 덤프를 만들고 PC로 사본(오프사이트)을 가져온 뒤 sha256으로 검증한다.
# 사용: ./backup.sh <db_ip> [저장 디렉터리, 기본 ~/dr-backup]
# 출력 파일: dku-<UTC시각>.sql.gz, .sha256, .meta(행 수와 데이터 해시, 마지막 행 시각)
set -euo pipefail

DB_IP="${1:?사용: $0 <db_ip> [저장 디렉터리]}"
DEST="${2:-$HOME/dr-backup}"
USER_NAME="${SSH_USER:-ubuntu}"
CTL="/tmp/dku-ssh-$$"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o "ControlPath=$CTL" -o ControlPersist=120)
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
NAME="dku-${STAMP}.sql.gz"

# macOS에는 sha256sum이 없어 shasum으로 대신한다
sha_check() { if command -v sha256sum >/dev/null 2>&1; then sha256sum -c "$1"; else shasum -a 256 -c "$1"; fi; }

mkdir -p "$DEST"
# DB VM을 destroy 후 다시 만들면 같은 IP에 호스트 키가 바뀌어 접속이 거부된다. 이 IP의 옛 키만 지우면 새 키는 accept-new가 다시 받는다.
ssh-keygen -R "$DB_IP" >/dev/null 2>&1 || true

trap 'ssh "${SSH_OPTS[@]}" -O exit "$USER_NAME@$DB_IP" 2>/dev/null || true' EXIT

echo "$(date -u +%FT%TZ) 백업 시작 (VM: $DB_IP)"

# 1) VM 안에서 덤프, 행 수, 데이터 해시, 마지막 행 시각을 한 번에 만든다
ssh "${SSH_OPTS[@]}" "$USER_NAME@$DB_IP" "set -e
  sudo mkdir -p /var/backups/dku
  sudo sh -c 'mysqldump --single-transaction --databases shop | gzip > /var/backups/dku/$NAME'
  cd /var/backups/dku
  sudo sh -c 'sha256sum $NAME > $NAME.sha256'
  ROWS=\$(sudo mysql -N -e 'SELECT COUNT(*) FROM shop.orders')
  HASH=\$(sudo mysql -N -e 'SELECT id,item,qty,created_at FROM shop.orders ORDER BY id' | sha256sum | cut -d' ' -f1)
  LAST=\$(sudo mysql -N -e 'SELECT MAX(created_at) FROM shop.orders')
  sudo sh -c \"printf 'rows=%s\ndata_sha256=%s\nlast_row_time=%s\nbackup_utc=%s\n' \$ROWS \$HASH '\$LAST' '$STAMP' > $NAME.meta\"
  sudo chmod 644 $NAME $NAME.sha256 $NAME.meta"

# 2) 본인 PC로 사본 복사
scp "${SSH_OPTS[@]}" "$USER_NAME@$DB_IP:/var/backups/dku/$NAME*" "$DEST/"

# 3) PC에서 sha256 검증
( cd "$DEST" && sha_check "$NAME.sha256" )

echo "$(date -u +%FT%TZ) 백업 완료: $DEST/$NAME"
cat "$DEST/$NAME.meta"
echo "위 backup_utc와 last_row_time이 RPO 계산의 기준이다."
