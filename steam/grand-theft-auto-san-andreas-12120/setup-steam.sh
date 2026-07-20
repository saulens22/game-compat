#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$case_dir/../../lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
pgrep -x steam >/dev/null && { echo 'Exit Steam before running this setup.' >&2; exit 1; }
controller_before=$(controller_config_fingerprint "$steam_root")
"$case_dir/install-fixes.sh"
"$case_dir/install-intro-codecs.sh"
"$case_dir/../../set-steam-compat-tool.sh" 12120 'Proton-GE Latest'
"$case_dir/../../set-steam-launch-options.sh" 12120 'WINEDLLOVERRIDES="vorbisFile=n,b" %command%'
"$case_dir/verify-install.sh"
controller_after=$(controller_config_fingerprint "$steam_root")
[[ "$controller_before" == "$controller_after" ]] || { echo 'Steam controller layout changed during setup.' >&2; exit 1; }
echo "PASS: Steam controller layout unchanged ($controller_after)."
