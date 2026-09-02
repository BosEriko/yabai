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

RESP=$(curl -sf --max-time 5 https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json")

UTIL=$(printf '%s' "$RESP" | /usr/bin/jq -r '.seven_day.utilization // empty' 2>/dev/null)
RESET_ISO=$(printf '%s' "$RESP" | /usr/bin/jq -r '.seven_day.resets_at // empty' 2>/dev/null)

if [ -n "$RESET_ISO" ]; then
  EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$(printf '%s' "$RESET_ISO" | cut -c1-19)" "+%s" 2>/dev/null)
  [ -n "$EPOCH" ] && RESET_HUMAN=$(date -r "$EPOCH" "+%a %b %d, %H:%M")
fi
[ -z "$RESET_HUMAN" ] && RESET_HUMAN="—"

if [ -z "$UTIL" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a" \
    --set "${NAME}.details" label="Claude resets ${RESET_HUMAN}"
else
  REMAIN=$(awk -v u="$UTIL" 'BEGIN {printf "%.0f", 100 - u}')
  sketchybar --set "$NAME" drawing=on label="${REMAIN}%" \
    --set "${NAME}.details" label="Claude resets ${RESET_HUMAN}"
fi
