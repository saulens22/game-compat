#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../../.." && pwd)
# shellcheck source=../../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
library=$EMULATION_ROOT
if pgrep -x retroarch >/dev/null || pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Exit RetroArch and Steam before rollback.' >&2
    exit 1
fi
marker=$library/metadata/last-config-backup
[[ -f $marker ]] || { echo 'No setup backup marker found.' >&2; exit 1; }
backup=$(<"$marker")
[[ -f $backup ]] || { echo "Backup not found: $backup" >&2; exit 1; }
config=${RETROARCH_CONFIG:-}
if [[ -z $config ]]; then
    config=$(steam_app_install_dir "$(resolve_steam_root)" 1118310)/retroarch.cfg
fi
[[ -f $config ]] || { echo 'RetroArch config not found.' >&2; exit 1; }
cp -a -- "$backup" "$config"
previous_options=$library/metadata/previous-launch-options
[[ -f $previous_options ]] || { echo 'Previous Steam launch options were not recorded.' >&2; exit 1; }
"$repo_root/set-steam-launch-options.sh" 1118310 "$(<"$previous_options")"
echo "Restored RetroArch config from $backup"
echo 'Restored the previous Steam launch options.'
echo 'Managed ROMs, saves, states, BIOS files, and cores were intentionally preserved.'
