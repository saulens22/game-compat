#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
yes=0
[[ ${1:-} == --yes ]] && { yes=1; shift; }
[[ $# -eq 0 ]] || { echo 'Usage: rollback-fixes.sh [--yes]' >&2; exit 2; }
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Exit Steam and the game before rollback. This script does not kill them.' >&2
    exit 1
fi
((yes)) || { read -r -p 'Restore Brotherhood configuration and prior Steam launch options? [y/N] ' answer; [[ $answer == [yY] ]]; }
steam_root=$(resolve_steam_root)
compatdata=$(steam_app_compatdata_dir "$steam_root" 48190)
config="$compatdata/pfx/drive_c/users/steamuser/Saved Games/Assassin's Creed Brotherhood/ACBrotherhood.ini"
backup="$case_dir/runtime/backups/original/ACBrotherhood.ini"
[[ -f $backup ]] || { echo 'No original configuration backup exists.' >&2; exit 1; }
cp -a -- "$backup" "$config"
previous='%command%'
[[ ! -f $case_dir/runtime/previous-launch-options ]] || previous=$(<"$case_dir/runtime/previous-launch-options")
"$repo_root/set-steam-launch-options.sh" 48190 "$previous"
rm -f -- "$case_dir/runtime/installed-version"
echo 'Restored Brotherhood configuration and previous Steam launch options.'
