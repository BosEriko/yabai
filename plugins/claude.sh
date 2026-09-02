#!/bin/sh

TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
  | /usr/bin/jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

if [ -z "$TOKEN" ]; then
  sketchybar --set "$NAME" label="n/a"
  exit 0
fi

UTIL=$(curl -sf --max-time 5 https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json" \
  | /usr/bin/jq -r '.seven_day.utilization // empty' 2>/dev/null)

if [ -z "$UTIL" ]; then
  sketchybar --set "$NAME" label="n/a"
else
  REMAIN=$(awk -v u="$UTIL" 'BEGIN {printf "%.0f", 100 - u}')
  sketchybar --set "$NAME" label="${REMAIN}%"
fi
