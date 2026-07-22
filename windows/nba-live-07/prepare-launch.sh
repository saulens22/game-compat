#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path nba-live-07)
ini="$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07/main.ini"
[[ -f $ini ]] || exit 0

width=${NBA_LIVE_07_WIDTH:-}
height=${NBA_LIVE_07_HEIGHT:-}
# Upstream documents 0 as true fullscreen. Windowed mode can leave NBA Live
# 07's restored backbuffer shorter than the client after Alt-Tab, which also
# shifts the widescreen plugin's mouse-coordinate conversion.
windowed=${NBA_LIVE_07_WINDOWED:-0}
if [[ -z $width || -z $height ]]; then
    if command -v kscreen-doctor >/dev/null; then
        display=$(kscreen-doctor -o | sed $'s/\033\[[0-9;]*m//g' |
            awk -v RS='Output:' '$0 ~ /enabled/ && $0 ~ /priority 1/ { print; exit }')
        mode=$(rg -o '[0-9]+x[0-9]+@[0-9.]+\*' <<<"$display" | head -n 1 || true)
        if [[ $mode =~ ^([0-9]+)x([0-9]+)@ ]]; then
            width=${BASH_REMATCH[1]}
            height=${BASH_REMATCH[2]}
        fi
    fi
fi

if [[ -z $width || -z $height ]]; then
    echo 'Could not detect the primary display mode.' >&2
    echo 'Set NBA_LIVE_07_WIDTH and NBA_LIVE_07_HEIGHT explicitly.' >&2
    exit 1
fi
[[ $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ && $width -ge 640 && $height -ge 480 ]] || {
    echo "Invalid requested resolution: ${width}x${height}" >&2
    exit 1
}
[[ $windowed == 0 || $windowed == 1 ]] || {
    echo "NBA_LIVE_07_WINDOWED must be 0 or 1, not: $windowed" >&2
    exit 1
}

sed -i \
    -e "s/^WINDOWED=.*/WINDOWED=$windowed/" \
    -e "s/^RES_X=.*/RES_X=$width/" \
    -e "s/^RES_Y=.*/RES_Y=$height/" \
    -e 's/^INTRO=.*/INTRO=1/' "$ini"
printf 'NBA Live 07 presentation prepared: %sx%s, windowed=%s\n' "$width" "$height" "$windowed"
