#!/usr/bin/env bash
# 실측 전
# 장애 대응 4개 시각을 timeline.csv에 기록한다.
# 사용: mark.sh 주입|감지|완화|복구 [메모]
set -euo pipefail

LABEL="${1:-}"
NOTE="${2:-}"
FILE="${TIMELINE:-timeline.csv}"

case "$LABEL" in
  주입|감지|완화|복구) ;;
  *) echo "사용: $0 주입|감지|완화|복구 [메모]" >&2; exit 1 ;;
esac

[ -f "$FILE" ] || echo "time_utc,label,note" > "$FILE"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "${TS},${LABEL},${NOTE}" >> "$FILE"
echo "${TS} ${LABEL} ${NOTE}  -> ${FILE}"
