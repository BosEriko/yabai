#!/bin/sh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

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

UTIL=$(curl -sf --max-time 5 https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json" \
  | /usr/bin/jq -r '.seven_day.utilization // empty' 2>/dev/null)

if [ -z "$UTIL" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a"
else
  REMAIN=$(awk -v u="$UTIL" 'BEGIN {printf "%.0f", 100 - u}')
  sketchybar --set "$NAME" drawing=on label="${REMAIN}%"
fi
