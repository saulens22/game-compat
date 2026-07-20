#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)

if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Exit Steam before running the trilogy setup.' >&2
    exit 1
fi

before=$(controller_config_fingerprint "$steam_root")

"$root/steam/grand-theft-auto-iii-12100/setup-steam.sh"
"$root/steam/grand-theft-auto-vice-city-12110/setup-steam.sh"
"$root/steam/grand-theft-auto-san-andreas-12120/setup-steam.sh"

after=$(controller_config_fingerprint "$steam_root")
[[ $before == "$after" ]] || {
    echo 'Steam controller configuration changed during trilogy setup.' >&2
    exit 1
}

echo "PASS: all three games configured; Steam controller configuration unchanged ($after)."
