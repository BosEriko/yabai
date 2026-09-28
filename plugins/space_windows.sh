#!/bin/sh

SID="${NAME#space.}"
SID="${SID%.count}"

DISPLAY=$(yabai -m query --spaces --space "$SID" 2>/dev/null | jq -r '.display // empty')
COUNT=$(yabai -m query --windows --space "$SID" 2>/dev/null | jq 'length')

[ -n "$DISPLAY" ] && sketchybar --set "$NAME" display="$DISPLAY"

if [ -z "$COUNT" ] || [ "$COUNT" = "0" ]; then
  sketchybar --set "$NAME" drawing=off
else
  sketchybar --set "$NAME" drawing=on label="$COUNT"
fi
