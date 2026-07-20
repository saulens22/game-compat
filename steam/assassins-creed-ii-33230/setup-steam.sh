#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)

if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Exit Steam before setup. This script does not kill Steam for you.' >&2
    exit 1
fi
before=$(controller_config_fingerprint "$steam_root")
mkdir -p "$case_dir/runtime"
previous_file="$case_dir/runtime/previous-launch-options"
[[ -e $previous_file ]] || steam_launch_options "$(steam_localconfig "$steam_root")" 33230 > "$previous_file"

"$case_dir/install-fixes.sh"
"$repo_root/set-steam-compat-tool.sh" 33230 'Proton-GE Latest'
"$repo_root/set-steam-launch-options.sh" 33230 'WINEDLLOVERRIDES="dinput8=n,b" %command%'
"$case_dir/verify-install.sh"
after=$(controller_config_fingerprint "$steam_root")
[[ $before == "$after" ]] || { echo 'Steam controller layout changed during setup.' >&2; exit 1; }
echo "PASS: Steam controller layout unchanged ($after)."
echo 'Restart Steam normally and launch App ID 33230.'
