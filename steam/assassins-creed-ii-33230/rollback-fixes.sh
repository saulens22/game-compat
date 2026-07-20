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
((yes)) || { read -r -p 'Remove AC2 fixes and restore the pre-install configuration? [y/N] ' answer; [[ $answer == [yY] ]]; }
steam_root=$(resolve_steam_root)
game_dir=$(steam_app_install_dir "$steam_root" 33230)
compatdata=$(steam_app_compatdata_dir "$steam_root" 33230)
originals="$case_dir/runtime/backups/original"

restore_or_remove() {
    local name=$1 target=$2
    if [[ -e $originals/$name ]]; then install -Dm644 "$originals/$name" "$target"
    else rm -f -- "$target"
    fi
}
restore_or_remove dinput8.dll "$game_dir/dinput8.dll"
restore_or_remove EaglePatchAC2.asi "$game_dir/scripts/EaglePatchAC2.asi"
restore_or_remove EaglePatchAC2.ini "$game_dir/scripts/EaglePatchAC2.ini"
config="$compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Ubisoft/Assassin's Creed 2/Assassin2.ini"
[[ ! -f $originals/Assassin2.ini ]] || cp -a -- "$originals/Assassin2.ini" "$config"
previous='%command%'; [[ ! -f $case_dir/runtime/previous-launch-options ]] || previous=$(<"$case_dir/runtime/previous-launch-options")
"$repo_root/set-steam-launch-options.sh" 33230 "$previous"
rm -f -- "$case_dir/runtime/installed-version"
echo 'Rolled back AC2 fixes and Steam launch options.'
