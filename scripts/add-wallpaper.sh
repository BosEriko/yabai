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

"$SCRIPT_DIR/renumber-wallpapers.sh"

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

orig_size=$(stat -f%z "$dest")
W=$(sips -g pixelWidth "$dest" | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight "$dest" | awk '/pixelHeight/{print $2}')
pair=$(awk -v w="$W" -v h="$H" 'BEGIN {
  scale = 1920/w
  if (1080/h > scale) scale = 1080/h
  if (scale > 1) scale = 1
  nw = int(w * scale); if (nw < 1920 && w >= 1920) nw = 1920
  nh = int(h * scale); if (nh < 1080 && h >= 1080) nh = 1080
  print nw, nh
}')
new_w=${pair%% *}
new_h=${pair##* }
if [ "$new_w" -lt "$W" ] || [ "$new_h" -lt "$H" ]; then
  sips -z "$new_h" "$new_w" "$dest" >/dev/null 2>&1
fi

if ! command -v optipng >/dev/null 2>&1; then
  brew install optipng >/dev/null 2>&1 || true
fi
if command -v optipng >/dev/null 2>&1; then
  optipng -quiet -o4 "$dest" >/dev/null 2>&1 || true
fi

final_size=$(stat -f%z "$dest")

cd "$REPO_DIR"
git add wallpaper
git commit -m "✨ Add wallpaper ${next_padded}"
git push origin main

echo "Added wallpaper/${next_padded}.png and pushed."
awk -v w="$W" -v h="$H" -v nw="$new_w" -v nh="$new_h" -v os="$orig_size" -v fs="$final_size" 'BEGIN {
  printf "Size: %dx%d -> %dx%d\n", w, h, nw, nh
  printf "File: %.2fMB -> %.2fMB\n", os / 1048576, fs / 1048576
}'
