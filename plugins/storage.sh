#!/bin/sh

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

read -r SIZE USED AVAIL CAPACITY <<< "$(df -H / | awk 'NR==2 {print $2, $3, $4, $5}')"

REMAIN=${CAPACITY%\%}
REMAIN=$((100 - REMAIN))

sketchybar --set "$NAME" label="${REMAIN}%" \
  --set "${NAME}.details" label="${AVAIL}/${SIZE}"
