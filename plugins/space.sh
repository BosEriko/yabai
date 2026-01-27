#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

WHITE=0xFFBCBCBC
YELLOW=0xFFFFDF20

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0xEB1e1e2e \
    icon.color=$YELLOW \
    background.border_color=$YELLOW
else
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0xEB1e1e2e \
    icon.color=$WHITE \
    background.border_color=$WHITE
fi
