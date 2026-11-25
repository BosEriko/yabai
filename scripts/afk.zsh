#!/bin/zsh

export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

zmodload zsh/mathfunc

IDLE_LIMIT=60
CHUNK=10

seconds_since() {
  osascript -l JavaScript -e "ObjC.import('CoreGraphics'); Math.min(...[$1].map(t => \$.CGEventSourceSecondsSinceLastEventType(1, t)))" 2>/dev/null
}

dims=($(osascript -l JavaScript -e 'ObjC.import("AppKit"); var f = $.NSScreen.screens.objectAtIndex(0).frame; f.size.width + " " + f.size.height'))
cx=$((int(dims[1]) - 100))
cy=$((int(dims[2]) - 100))
radius=40
points=240
two_pi=6.283185307

xs=()
ys=()
for ((i = 0; i < points; i++)); do
  angle=$((i * two_pi / points))
  xs+=($((cx + int(radius * cos(angle)))))
  ys+=($((cy + int(radius * sin(angle)))))
done

positions=()
moves=()
for ((i = 1; i <= points; i++)); do
  previous=$(( i == 1 ? points : i - 1 ))
  positions+=("${xs[i]},${ys[i]}")
  moves+=("$(printf 'm:%+d,%+d' $((xs[i] - xs[previous])) $((ys[i] - ys[previous])))")
done

while true; do
  idle=$(seconds_since 1,3,5,6,7,22,25,27)
  if (( ${idle:-0} < IDLE_LIMIT )); then
    sleep 5
    continue
  fi

  cliclick "m:${positions[points]}"
  active=0
  while (( ! active )); do
    for ((i = 1; i <= points; i += CHUNK)); do
      cliclick -w 20 "${(@)moves[i,i+CHUNK-1]}"
      if [[ "$(cliclick p)" != "${positions[i+CHUNK-1]}" ]]; then
        active=1
        break
      fi
      clicked=$(seconds_since 1,3,22,25)
      if (( ${clicked:-0} < 2 )); then
        active=1
        break
      fi
    done
  done
done
