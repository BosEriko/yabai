#!/bin/sh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

case "$SENDER" in
  mouse.entered)
    sketchybar --set "$NAME" popup.drawing=on
    exit 0
    ;;
  mouse.exited|mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off
    exit 0
    ;;
esac

if ! command -v claude >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
  | /usr/bin/jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

if [ -z "$TOKEN" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

CACHE="$HOME/.cache/sketchybar_claude_usage.json"
mkdir -p "$HOME/.cache"

RESP=$(curl -sf --max-time 5 https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json")

if printf '%s' "$RESP" | /usr/bin/jq -e '.seven_day.utilization != null and .seven_day.resets_at != null' >/dev/null 2>&1; then
  printf '%s' "$RESP" > "$CACHE"
elif [ -f "$CACHE" ]; then
  RESP=$(cat "$CACHE")
fi

UTIL=$(printf '%s' "$RESP" | /usr/bin/jq -r '.seven_day.utilization // empty' 2>/dev/null)
RESET_ISO=$(printf '%s' "$RESP" | /usr/bin/jq -r '.seven_day.resets_at // empty' 2>/dev/null)

if [ -n "$RESET_ISO" ]; then
  EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$(printf '%s' "$RESET_ISO" | cut -c1-19)" "+%s" 2>/dev/null)
  if [ -n "$EPOCH" ]; then
    EPOCH=$(( (EPOCH + 30) / 60 * 60 ))
    RESET_HUMAN=$(date -r "$EPOCH" "+%a %b %d, %H:%M")
  fi
fi
[ -z "$RESET_HUMAN" ] && RESET_HUMAN="—"

if [ -z "$UTIL" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a" background.border_color=0xFFBCBCBC \
    --set "${NAME}.details" label="Claude usage unavailable"
else
  REMAIN=$(awk -v u="$UTIL" 'BEGIN {printf "%.0f", 100 - u}')
  ICON_COLOR=0xFFBCBCBC
  if [ -n "$EPOCH" ]; then
    OUT=$(/usr/bin/python3 - "$EPOCH" "$UTIL" <<'EOF'
import sys, time
from datetime import datetime, timedelta

reset = float(sys.argv[1])
util = float(sys.argv[2])
now = time.time()
start = reset - 7 * 86400


def wsec(a, b):
    if b <= a:
        return 0.0
    total = 0.0
    cur = datetime.fromtimestamp(a)
    end = datetime.fromtimestamp(b)
    while cur < end:
        nxt = min(cur.replace(hour=0, minute=0, second=0, microsecond=0)
                  + timedelta(days=1), end)
        if cur.weekday() < 5:
            total += (nxt - cur).total_seconds()
        cur = nxt
    return total


work_total = wsec(start, reset)
trem = 0.0 if work_total <= 0 else 100.0 * wsec(now, reset) / work_total
print("%.0f%%" % ((100.0 - util) - trem))

COLORS = ["0xFF22C55E", "0xFF65A30D", "0xFFA3A30A", "0xFFEAB308",
          "0xFFF59E0B", "0xFFF97316", "0xFFEF4444"]
frac = max(0.0, min(1.0, (reset - now) / (7 * 86400)))
idx = min(6, int((1.0 - frac) * 7))
print(COLORS[idx])
EOF
)
    LABEL=$(printf '%s\n' "$OUT" | sed -n '1p')
    ICON_COLOR=$(printf '%s\n' "$OUT" | sed -n '2p')
  else
    LABEL="${REMAIN}%"
  fi
  NUM=${LABEL%\%}
  if [ "$NUM" -le 0 ] 2>/dev/null; then
    BORDER=0xFFCE3A5B
  else
    BORDER=0xFFBCBCBC
  fi
  sketchybar --set "$NAME" drawing=on label="${LABEL}" icon.color="$ICON_COLOR" background.border_color="$BORDER" \
    --set "${NAME}.details" label="Claude has ${REMAIN}% tokens remaining before the weekly reset on ${RESET_HUMAN}"
fi
