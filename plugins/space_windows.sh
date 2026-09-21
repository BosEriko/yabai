#!/bin/sh

SID="${NAME#space.}"
SID="${SID%.count}"

COUNT=$(yabai -m query --windows --space "$SID" 2>/dev/null | jq 'length')

if [ -z "$COUNT" ] || [ "$COUNT" = "0" ]; then
  sketchybar --set "$NAME" drawing=off
else
  sketchybar --set "$NAME" drawing=on label="$COUNT"
fi
