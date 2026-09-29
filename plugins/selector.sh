#!/bin/sh

STATE_DIR="${TMPDIR:-/tmp}/sketchybar-selector-${USER}"
CONFIG_FILE="$STATE_DIR/config"
INDEX_FILE="$STATE_DIR/index"
COUNT_FILE="$STATE_DIR/count"
SESSION_FILE="$STATE_DIR/session"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAX_ITEMS=9

render() {
  [ -r "$CONFIG_FILE" ] && [ -r "$INDEX_FILE" ] && [ -r "$COUNT_FILE" ] || return 0

  config=$(cat "$CONFIG_FILE")
  selected=$(cat "$INDEX_FILE")
  count=$(cat "$COUNT_FILE")
  i=1
  set --

  while [ "$i" -le "$((MAX_ITEMS + 1))" ]; do
    if [ "$i" -le "$((count + 1))" ]; then
      if [ "$i" -eq "$((count + 1))" ]; then
        label="Open all"
        key=a
      else
        label=$(sed -n "${i}s/\t.*//p" "$config")
        key=$i
      fi
      set -- "$@" --set "selector.$i" drawing=on label="$label" icon.drawing=on icon="$key" background.drawing=off
    else
      set -- "$@" --set "selector.$i" drawing=off
    fi
    i=$((i + 1))
  done
  highlight="$STATE_DIR/highlight-$count-$selected.png"
  "$STATE_DIR/selector-mouse" --highlight 240 40 12 "$((count + 1))" "$selected" "$highlight" || return 1
  sketchybar "$@" --set selector popup.background.image="$highlight"
}

close() {
  [ ! -d "$STATE_DIR" ] || printf '\n' > "$SESSION_FILE"
  sketchybar --set selector popup.drawing=off drawing=off
}

case "$1" in
  open)
    [ -r "$2" ] || exit 1
    yabai -m space --focus "$3" >/dev/null 2>&1
    "$SCRIPT_DIR/selector.sh" show "$2" || exit 1
    skhd -k f20
    ;;
  show)
    config=$2
    [ -r "$config" ] || exit 1
    count=$(awk -F '\t' 'NF != 2 || $1 == "" || $2 == "" { invalid = 1 } END { if (invalid) exit 1; print NR }' "$config") || exit 1
    [ "$count" -gt 0 ] || exit 1
    [ "$count" -le "$MAX_ITEMS" ] || exit 1
    display=$(yabai -m query --displays --display) || exit 1
    display_index=$(printf '%s\n' "$display" | jq -er '.index') || exit 1
    mkdir -p "$STATE_DIR"
    if [ ! -x "$STATE_DIR/selector-mouse" ] || [ "$SCRIPT_DIR/../scripts/selector-mouse.swift" -nt "$STATE_DIR/selector-mouse" ]; then
      swiftc -module-cache-path "$STATE_DIR/swift-cache" "$SCRIPT_DIR/../scripts/selector-mouse.swift" -o "$STATE_DIR/selector-mouse" || { skhd -k escape; exit 1; }
    fi
    printf '%s\n' "$config" > "$CONFIG_FILE"
    printf '1\n' > "$INDEX_FILE"
    printf '%s\n' "$count" > "$COUNT_FILE"
    render
    sketchybar --set selector display="$display_index" drawing=on popup.drawing=off
    selector=$(sketchybar --query selector) || exit 1
    offset=$(printf '%s\n' "$selector" | jq -er \
      --argjson display "$display" --argjson count "$((count + 1))" '
        .bounding_rects["display-\($display.index)"] as $anchor |
        ($display.frame.y + ($display.frame.h - ($count * .popup.height + 2 * .popup.background.border_width)) / 2
         - $anchor.origin[1] - $anchor.size[1]) | floor
      ') || exit 1
    sketchybar --set selector popup.y_offset="$offset" popup.drawing=on
    printf '%s\n' "$$" > "$SESSION_FILE"
    "$STATE_DIR/selector-mouse" "$SESSION_FILE" "$$" "$SCRIPT_DIR/selector.sh" >/dev/null 2>&1 &
    ;;
  up|down)
    [ -r "$INDEX_FILE" ] && [ -r "$COUNT_FILE" ] || exit 1
    index=$(cat "$INDEX_FILE")
    count=$(cat "$COUNT_FILE")
    count=$((count + 1))
    if [ "$1" = "up" ]; then
      index=$((index - 1))
      [ "$index" -ge 1 ] || index=$count
    else
      index=$((index + 1))
      [ "$index" -le "$count" ] || index=1
    fi
    printf '%s\n' "$index" > "$INDEX_FILE"
    render
    ;;
  all|select|choose|number)
    [ -r "$CONFIG_FILE" ] && [ -r "$INDEX_FILE" ] && [ -r "$COUNT_FILE" ] || exit 1
    count=$(cat "$COUNT_FILE")
    if [ "$1" = "all" ]; then
      index=$((count + 1))
    elif [ "$1" = "number" ]; then
      case "$2" in
        [1-9]) index=$2 ;;
        *) exit 0 ;;
      esac
      [ "$index" -le "$count" ] || exit 0
    elif [ "$1" = "choose" ]; then
      index=$2
      count=$(cat "$COUNT_FILE")
      [ "$index" -ge 1 ] 2>/dev/null && [ "$index" -le "$((count + 1))" ] || exit 1
      printf '%s\n' "$index" > "$INDEX_FILE"
    else
      index=$(cat "$INDEX_FILE")
    fi
    config=$(cat "$CONFIG_FILE")
    if [ "$index" -eq "$((count + 1))" ]; then
      close
      while IFS="$(printf '\t')" read -r label action; do
        [ -z "$action" ] || /bin/sh -c "$action"
      done < "$config"
      skhd -k escape
      exit 0
    fi
    action=$(sed -n "${index}s/^[^	]*	//p" "$config")
    [ -n "$action" ] || exit 1
    close
    /bin/sh -c "$action"
    skhd -k "escape"
    ;;
  close)
    close
    ;;
  cancel)
    [ "$(cat "$SESSION_FILE" 2>/dev/null)" = "$2" ] || exit 0
    close
    skhd -k escape
    ;;
  *)
    exit 1
    ;;
esac
