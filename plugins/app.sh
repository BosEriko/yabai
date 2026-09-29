#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mode=${1:-}
app_id=${2:-}
space=${3:-}

case "$mode" in
  open|install) ;;
  *) exit 1 ;;
esac
case "$app_id" in
  ''|*[!a-z0-9-]*) exit 1 ;;
esac
case "$space" in
  ''|*[!0-9]*|0) exit 1 ;;
esac

entry=$(awk -F '\t' -v id="$app_id" '$1 == id && NF == 3 { print $2 "\t" $3; found++ } END { if (found != 1) exit 1 }' "$SCRIPT_DIR/../apps.tsv") || {
  printf 'Unknown application: %s\n' "$app_id" >&2
  exit 1
}
IFS="$(printf '\t')" read -r app cask <<EOF
$entry
EOF

installed() {
  [ -d "/Applications/$app.app" ] || [ -d "$HOME/Applications/$app.app" ] ||
    { [ "$cask" = - ] && [ -d "/System/Library/CoreServices/$app.app" ]; }
}

launch() {
  yabai -m space --focus "$space" && open -a "$app"
}

if installed; then
  launch
  exit $?
fi

if [ "$cask" = - ]; then
  printf '%s is a built-in macOS application and cannot be installed with Homebrew.\n' "$app" >&2
  exit 1
fi

if [ "$mode" = open ]; then
  osascript "$SCRIPT_DIR/app-terminal.applescript" "$SCRIPT_DIR/app.sh" "$app_id" "$space"
  exit $?
fi

lock_dir="${TMPDIR:-/tmp}/yabai-app-installs-$(id -u)"
mkdir -p "$lock_dir" || exit 1
lock_file="$lock_dir/$app_id.lock"
if ! shlock -p "$$" -f "$lock_file"; then
  printf '%s is already being installed in another terminal.\n' "$app"
  exit 0
fi
trap 'rm -f "$lock_file"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

if installed; then
  launch
  exit $?
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required. Install it from https://brew.sh, then try again.\n' >&2
  exit 1
fi

operation=install
if brew list --cask "$cask" >/dev/null 2>&1; then
  operation=reinstall
fi
printf 'Installing %s with Homebrew…\n' "$app"
if ! brew "$operation" --cask "$cask"; then
  printf 'Installation failed for %s. Review the error above and retry the shortcut.\n' "$app" >&2
  exit 1
fi

printf 'Opening %s…\n' "$app"
launch
