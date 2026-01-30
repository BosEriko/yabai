#!/bin/sh

# Total RAM in GB
TOTAL=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')

# Used memory in MB from top
USED_MB=$(top -l 1 -n 0 | awk '/PhysMem:/ {print $2}' | sed 's/M//')

# Convert MB → GB
USED_GB=$(awk -v u="$USED_MB" 'BEGIN {printf "%.1f", u/1024}')

# Set SketchyBar label
sketchybar --set "$NAME" label="${USED_GB}G/${TOTAL}G"
