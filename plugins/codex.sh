#!/bin/sh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

AUTH="$HOME/.codex/auth.json"
if ! command -v codex >/dev/null 2>&1 || \
   ! /usr/bin/jq -e '((.tokens.access_token // "") != "") or ((.OPENAI_API_KEY // "") != "")' "$AUTH" >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

PCT=$(/usr/bin/python3 - <<'EOF'
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
    used = best[1].get("secondary", {}).get("used_percent")
    if used is not None:
        print(int(round(100 - used)))
EOF
)

if [ -z "$PCT" ]; then
  sketchybar --set "$NAME" drawing=on label="n/a"
else
  sketchybar --set "$NAME" drawing=on label="${PCT}%"
fi
