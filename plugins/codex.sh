#!/bin/sh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

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

AUTH="$HOME/.codex/auth.json"
if ! command -v codex >/dev/null 2>&1 || \
   ! /usr/bin/jq -e '((.tokens.access_token // "") != "") or ((.OPENAI_API_KEY // "") != "")' "$AUTH" >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

OUT=$(/usr/bin/python3 - <<'EOF'
import glob, json, os

files = glob.glob(os.path.expanduser("~/.codex/sessions/**/*.jsonl"), recursive=True)
best = None
for f in files:
    try:
        with open(f) as fh:
            for line in fh:
                if '"rate_limits"' not in line:
                    continue
                try:
                    o = json.loads(line)
                except ValueError:
                    continue
                rl = o.get("payload", {}).get("rate_limits")
                ts = o.get("timestamp")
                if rl and ts and (best is None or ts > best[0]):
                    best = (ts, rl)
    except (FileNotFoundError, OSError):
        pass

if best:
    sec = best[1].get("secondary", {})
    used = sec.get("used_percent")
    resets = sec.get("resets_at")
    print(int(round(100 - used)) if used is not None else "")
    print(resets if resets is not None else "")
EOF
)

PCT=$(printf '%s\n' "$OUT" | sed -n '1p')
RESET_EPOCH=$(printf '%s\n' "$OUT" | sed -n '2p')

if [ -n "$RESET_EPOCH" ]; then
  RESET_HUMAN=$(date -r "$RESET_EPOCH" "+%a %b %d, %H:%M" 2>/dev/null)
fi
[ -z "$RESET_HUMAN" ] && RESET_HUMAN="—"

if [ -z "$PCT" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a" \
    --set "${NAME}.details" label="Codex resets ${RESET_HUMAN}"
else
  sketchybar --set "$NAME" drawing=on label="${PCT}%" \
    --set "${NAME}.details" label="Codex resets ${RESET_HUMAN}"
fi
