#!/bin/sh

WHITE=0xFFBCBCBC
GREEN=0xFF34A853

BATT="$(pmset -g batt)"
PERCENTAGE="$(printf '%s\n' "$BATT" | grep -Eo "[0-9]+%" | head -1 | cut -d% -f1)"

if [ -z "$PERCENTAGE" ] || ! printf '%s\n' "$BATT" | grep -q "discharging"; then
  if [ -n "$PERCENTAGE" ] && [ "$PERCENTAGE" -gt 90 ] 2>/dev/null; then
    CPU_BORDER=$GREEN
  else
    CPU_BORDER=$WHITE
  fi
  sketchybar --set "$NAME" drawing=off --set cpu drawing=on background.border_color="$CPU_BORDER"
  exit 0
fi

sketchybar --set cpu background.border_color=$WHITE

case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""
  ;;
  [6-8][0-9]) ICON=""
  ;;
  [3-5][0-9]) ICON=""
  ;;
  [1-2][0-9]) ICON=""
  ;;
  *) ICON=""
esac

sketchybar --set "$NAME" drawing=on icon="$ICON" label="${PERCENTAGE}%" --set cpu drawing=off
