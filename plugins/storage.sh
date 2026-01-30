#!/bin/sh

read -r SIZE USED AVAIL <<< "$(df -H / | awk 'NR==2 {print $2, $3, $4}')"

sketchybar --set "$NAME" label="$AVAIL/$SIZE"
