#!/bin/sh

BATT="$(pmset -g batt)"
PERCENTAGE="$(printf '%s\n' "$BATT" | grep -Eo "[0-9]+%" | head -1 | cut -d% -f1)"

if [ -z "$PERCENTAGE" ] || ! printf '%s\n' "$BATT" | grep -q "discharging"; then
  sketchybar --set "$NAME" drawing=off --set cpu drawing=on
  exit 0
fi

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
