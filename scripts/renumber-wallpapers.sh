#!/bin/sh
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR="$SCRIPT_DIR/.."

cd "$REPO_DIR"

i=1
for f in $(find wallpaper -maxdepth 1 -type f -name '*.png' | sort); do
  new_name=$(printf "%04d.png" "$i")
  new_path="wallpaper/$new_name"
  if [ "$f" != "$new_path" ]; then
    git mv "$f" "$new_path"
    echo "Renamed $(basename "$f") -> $new_name"
  fi
  i=$((i + 1))
done
