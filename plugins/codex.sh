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
import glob, json, os, time
from datetime import datetime, timedelta

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

cache = os.path.join(os.environ.get("TMPDIR", "/tmp"), "sketchybar_codex_usage.json")

used = resets = None
if best:
    sec = best[1].get("secondary", {})
    used = sec.get("used_percent")
    resets = sec.get("resets_at")

if used is not None and resets is not None:
    try:
        with open(cache, "w") as fh:
            json.dump({"used_percent": used, "resets_at": resets}, fh)
    except OSError:
        pass
elif os.path.exists(cache):
    try:
        with open(cache) as fh:
            c = json.load(fh)
        used = c.get("used_percent")
        resets = c.get("resets_at")
    except (OSError, ValueError):
        pass

if used is None or resets is None:
    raise SystemExit(0)

reset = (int(resets) + 30) // 60 * 60
now = time.time()
start = reset - 7 * 86400


def wsec(a, b):
    if b <= a:
        return 0.0
    total = 0.0
    cur = datetime.fromtimestamp(a)
    end = datetime.fromtimestamp(b)
    while cur < end:
        nxt = min(cur.replace(hour=0, minute=0, second=0, microsecond=0)
                  + timedelta(days=1), end)
        if cur.weekday() < 5:
            total += (nxt - cur).total_seconds()
        cur = nxt
    return total


work_total = wsec(start, reset)
trem = 0.0 if work_total <= 0 else 100.0 * wsec(now, reset) / work_total

print("%.0f%%" % ((100.0 - used) - trem))
print(round(100.0 - used))
print(datetime.fromtimestamp(reset).strftime("%a %b %d, %H:%M"))
EOF
)

LABEL=$(printf '%s\n' "$OUT" | sed -n '1p')
REMAIN=$(printf '%s\n' "$OUT" | sed -n '2p')
RESET_HUMAN=$(printf '%s\n' "$OUT" | sed -n '3p')

if [ -z "$LABEL" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a" \
    --set "${NAME}.details" label="Codex usage unavailable"
else
  sketchybar --set "$NAME" drawing=on label="${LABEL}" \
    --set "${NAME}.details" label="Codex has ${REMAIN}% tokens remaining before the weekly reset on ${RESET_HUMAN}"
fi
