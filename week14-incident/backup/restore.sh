#!/usr/bin/env bash
# 실측 전
# 본인 PC에서 실행한다. 새 DB VM에 백업을 올려 복원하고 sha256, 행 수, 데이터 해시를 검증한다.
# 사용: ./restore.sh <새_db_ip> <백업 파일 경로(.sql.gz)>
# 같은 위치에 .sha256, .meta 파일이 있어야 한다.
set -euo pipefail

DB_IP="${1:?사용: $0 <db_ip> <백업파일.sql.gz>}"
FILE="${2:?사용: $0 <db_ip> <백업파일.sql.gz>}"
USER_NAME="${SSH_USER:-ubuntu}"
CTL="/tmp/dku-ssh-$$"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o "ControlPath=$CTL" -o ControlPersist=120)
DIR="$(cd "$(dirname "$FILE")" && pwd)"
NAME="$(basename "$FILE")"

# macOS에는 sha256sum이 없어 shasum으로 대신한다
sha_check() { if command -v sha256sum >/dev/null 2>&1; then sha256sum -c "$1"; else shasum -a 256 -c "$1"; fi; }

# DB VM을 destroy 후 다시 만들면 같은 IP에 호스트 키가 바뀌어 접속이 거부된다. 이 IP의 옛 키만 지우면 새 키는 accept-new가 다시 받는다.
ssh-keygen -R "$DB_IP" >/dev/null 2>&1 || true

trap 'ssh "${SSH_OPTS[@]}" -O exit "$USER_NAME@$DB_IP" 2>/dev/null || true' EXIT

echo "$(date -u +%FT%TZ) 복원 시작"

# 1) PC에서 먼저 무결성 확인
( cd "$DIR" && sha_check "$NAME.sha256" )
EXPECT_ROWS="$(grep '^rows=' "$DIR/$NAME.meta" | cut -d= -f2)"
EXPECT_HASH="$(grep '^data_sha256=' "$DIR/$NAME.meta" | cut -d= -f2)"

# 2-0) 새 VM은 sshd가 뜨고 cloud-init이 비밀번호를 설정할 때까지 수십 초 걸린다. 접속될 때까지 최대 약 3분 재시도한다
echo "SSH 접속 대기 (새 VM 부팅 중이면 수십 초 걸린다)"
for i in $(seq 1 36); do
  if (exec 3<>"/dev/tcp/$DB_IP/22") 2>/dev/null && ssh "${SSH_OPTS[@]}" -o ConnectTimeout=5 "$USER_NAME@$DB_IP" true 2>/dev/null; then break; fi
  [ "$i" = 36 ] && { echo "SSH 접속 실패: $DB_IP"; exit 1; }
  sleep 5
done
# 2) 새 VM이 준비될 때까지 대기(cloud-init) 후 파일 업로드
ssh "${SSH_OPTS[@]}" "$USER_NAME@$DB_IP" "cloud-init status --wait >/dev/null 2>&1 || true; command -v mysql >/dev/null"
scp "${SSH_OPTS[@]}" "$DIR/$NAME" "$DIR/$NAME.sha256" "$USER_NAME@$DB_IP:~/"

# 3) VM 안에서 해시 재검증, 복원, 검증
ssh "${SSH_OPTS[@]}" "$USER_NAME@$DB_IP" "set -e
  sha256sum -c $NAME.sha256
  gunzip -c $NAME | sudo mysql
  ROWS=\$(sudo mysql -N -e 'SELECT COUNT(*) FROM shop.orders')
  HASH=\$(sudo mysql -N -e 'SELECT id,item,qty,created_at FROM shop.orders ORDER BY id' | sha256sum | cut -d' ' -f1)
  echo rows=\$ROWS
  echo data_sha256=\$HASH
  [ \"\$ROWS\" = '$EXPECT_ROWS' ] || { echo '행 수 불일치'; exit 1; }
  [ \"\$HASH\" = '$EXPECT_HASH' ] || { echo '데이터 해시 불일치'; exit 1; }
  echo '검증 통과: 행 수와 데이터 해시가 백업 시점과 같다'"

echo "$(date -u +%FT%TZ) 복원 완료 (이 시각이 T1, 서비스 가능 확인 시각)"
