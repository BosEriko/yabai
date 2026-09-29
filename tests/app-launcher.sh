#!/bin/sh
set -eu

case "$(basename "$0")" in
  brew)
    printf 'brew %s\n' "$*" >> "$APP_TEST_LOG"
    if [ "$1" = list ]; then exit "${APP_TEST_LISTED:-1}"; fi
    exit "${APP_TEST_FAIL:-0}"
    ;;
  open|yabai|osascript|sketchybar|skhd)
    printf '%s %s\n' "$(basename "$0")" "$*" >> "$APP_TEST_LOG"
    exit 0
    ;;
esac

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/app-launcher-test.XXXXXX")
test_dir=$(CDPATH= cd -- "$test_dir" && pwd)
mkdir -p "$test_dir/plugins" "$test_dir/bin" "$test_dir/state"
cp "$repo/plugins/app.sh" "$repo/plugins/selector.sh" "$test_dir/plugins/"
for command in brew open yabai osascript sketchybar skhd; do
  ln -s "$repo/tests/app-launcher.sh" "$test_dir/bin/$command"
done
export PATH="$test_dir/bin:$PATH"
export TMPDIR="$test_dir/state"
export APP_TEST_LOG="$test_dir/commands"
printf 'finder\tFinder\t-\nmissing\tYabai Launcher Test Missing\tmissing-cask\nsecond\tYabai Launcher Test Second\tsecond-cask\n' > "$test_dir/apps.tsv"
launcher="$test_dir/plugins/app.sh"

: > "$APP_TEST_LOG"
"$launcher" open finder 8
test "$(cat "$APP_TEST_LOG")" = "$(printf 'yabai -m space --focus 8\nopen -a Finder')"

: > "$APP_TEST_LOG"
"$launcher" open missing 4
test "$(wc -l < "$APP_TEST_LOG" | tr -d ' ')" = 1
grep -F "osascript $test_dir/plugins/app-terminal.applescript $launcher missing 4" "$APP_TEST_LOG"

: > "$APP_TEST_LOG"
"$launcher" install missing 4
grep -Fx 'brew install --cask missing-cask' "$APP_TEST_LOG"
test "$(tail -2 "$APP_TEST_LOG")" = "$(printf 'yabai -m space --focus 4\nopen -a Yabai Launcher Test Missing')"

: > "$APP_TEST_LOG"
APP_TEST_LISTED=0 "$launcher" install missing 4
grep -Fx 'brew reinstall --cask missing-cask' "$APP_TEST_LOG"

: > "$APP_TEST_LOG"
if APP_TEST_FAIL=1 "$launcher" install missing 4; then exit 1; fi
if grep -q '^open ' "$APP_TEST_LOG"; then exit 1; fi

: > "$APP_TEST_LOG"
shlock -p "$$" -f "$TMPDIR/yabai-app-installs-$(id -u)/missing.lock"
"$launcher" install missing 4
test ! -s "$APP_TEST_LOG"

: > "$APP_TEST_LOG"
if "$launcher" open unknown 4; then exit 1; fi
if "$launcher" open missing '4; bad'; then exit 1; fi
test ! -s "$APP_TEST_LOG"

selector_state="$TMPDIR/sketchybar-selector-$USER"
mkdir -p "$selector_state"
printf 'First\t"%s" open missing 3\nSecond\t"%s" open second 3\n' "$launcher" "$launcher" > "$test_dir/selector.tsv"
printf '%s\n' "$test_dir/selector.tsv" > "$selector_state/config"
printf '2\n' > "$selector_state/count"
printf '1\n' > "$selector_state/index"
: > "$APP_TEST_LOG"
"$test_dir/plugins/selector.sh" all
test "$(grep -c '^osascript ' "$APP_TEST_LOG")" = 2
grep -F "$launcher missing 3" "$APP_TEST_LOG"
grep -F "$launcher second 3" "$APP_TEST_LOG"

awk -F '\t' 'NF != 3 || seen[$1]++ { exit 1 } END { if (NR != 10) exit 1 }' "$repo/apps.tsv"
printf 'PASS: installed, missing, install, reinstall, failure, duplicate, invalid input, and selector open-all paths\n'
