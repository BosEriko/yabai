#!/bin/sh
set -e

URL="$1"
if [ -z "$URL" ]; then
  echo "Usage: add-wallpaper.sh <url>" >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR="$SCRIPT_DIR/.."
WALLPAPER_DIR="$REPO_DIR/wallpaper"

mkdir -p "$WALLPAPER_DIR"

last=0
for f in "$WALLPAPER_DIR"/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  num=${base%%.*}
  case "$num" in
    ''|*[!0-9]*) continue ;;
  esac
  num=$((10#$num))
  [ "$num" -gt "$last" ] && last=$num
done
next_padded=$(printf "%04d" "$((last + 1))")

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

if ! curl -fsSL -o "$tmp_file" "$URL"; then
  echo "Download failed: $URL" >&2
  exit 1
fi

dest="$WALLPAPER_DIR/${next_padded}.png"
if ! sips -s format png "$tmp_file" --out "$dest" >/dev/null 2>&1; then
  echo "Conversion failed (not a valid image?): $URL" >&2
  exit 1
fi

cd "$REPO_DIR"
git add "$dest"
git commit -m "✨ Add wallpaper ${next_padded}"
git push origin main

echo "Added wallpaper/${next_padded}.png and pushed."
