#!/bin/sh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

YELLOW=0xFFFFDF20
WHITE=0xFFBCBCBC

STATE_DIR="$HOME/.cache/sketchybar-afk-${USER}"
ENABLED_FILE="$STATE_DIR/enabled"
PID_FILE="$STATE_DIR/pid"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NAME=${NAME:-afk}

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

mkdir -p "$STATE_DIR"

if [ "$1" = "toggle" ] || [ "$SENDER" = "mouse.clicked" ]; then
  if [ -f "$ENABLED_FILE" ]; then
    rm -f "$ENABLED_FILE"
  else
    : > "$ENABLED_FILE"
  fi
fi

pid=$(cat "$PID_FILE" 2>/dev/null)
running=0
if [ -n "$pid" ] && ps -p "$pid" -o command= 2>/dev/null | grep -q 'afk\.zsh'; then
  running=1
fi

if [ -f "$ENABLED_FILE" ] && ! command -v cliclick >/dev/null 2>&1; then
  sketchybar --set "$NAME" label="Installing" icon.color="$YELLOW" background.border_color="$YELLOW"
  find "$STATE_DIR" -maxdepth 1 -name installing -mmin +10 -exec rmdir {} \;
  mkdir "$STATE_DIR/installing" 2>/dev/null || exit 0
  brew install cliclick >/dev/null 2>&1 || rm -f "$ENABLED_FILE"
  rmdir "$STATE_DIR/installing"
fi

if [ -f "$ENABLED_FILE" ]; then
  if [ "$running" -eq 0 ]; then
    nohup "$SCRIPT_DIR/../scripts/afk.zsh" >/dev/null 2>&1 &
    printf '%s\n' "$!" > "$PID_FILE"
  fi
  COLOR=$YELLOW
  LABEL="On"
else
  if [ "$running" -eq 1 ]; then
    pkill -P "$pid"
    kill "$pid"
  fi
  rm -f "$PID_FILE"
  COLOR=$WHITE
  LABEL="Off"
fi

sketchybar --set "$NAME" label="$LABEL" icon.color="$COLOR" background.border_color="$COLOR"
