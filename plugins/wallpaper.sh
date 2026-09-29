#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WALLPAPER_DIR="$SCRIPT_DIR/../wallpaper"
STATE_FILE="$SCRIPT_DIR/../.wallpaper_index"

if ! command -v desktoppr >/dev/null 2>&1; then
  osascript -e 'display dialog "desktoppr is not installed.\n\nRun this in Terminal, then try again:\nbrew install --cask desktoppr" with title "Wallpaper Cycle" buttons {"OK"} default button "OK"'
  exit 1
fi

MODE="$1"

set --
for f in $(find "$WALLPAPER_DIR" -maxdepth 1 -type f | sort); do
  set -- "$@" "$f"
done
count=$#
[ "$count" -gt 0 ] || exit 1

index=0
if [ -r "$STATE_FILE" ]; then
  saved=$(cat "$STATE_FILE")
  case "$saved" in
    ''|*[!0-9]*) index=0 ;;
    *) [ "$saved" -lt "$count" ] && index=$saved ;;
  esac
fi

case "$MODE" in
  prev)
    index=$(( (index - 1 + count) % count ))
    ;;
  next)
    index=$(( (index + 1) % count ))
    ;;
  sync) ;;
  *)
    index=$(( (index + 1) % count ))
    ;;
esac

eval "file=\${$((index + 1))}"

current=$(desktoppr 2>/dev/null | sed -n '1p')
[ "$current" = "$file" ] || desktoppr 0 "$file"

printf '%s\n' "$index" > "$STATE_FILE"
