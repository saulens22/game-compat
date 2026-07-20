#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
game_dir=$(steam_app_install_dir "$steam_root" 15100)
compatdata=$(steam_app_compatdata_dir "$steam_root" 15100)
config="$compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Ubisoft/Assassin's Creed/Assassin.ini"
expected_options='WINEDLLOVERRIDES="dinput8=n,b" MANGOHUD_CONFIG="fps_limit=60,no_display" mangohud --dlsym %command%'

check_hash() {
    local expected=$1 file=$2 actual
    [[ -f $file ]] || { echo "FAIL: missing $file" >&2; exit 1; }
    actual=$(sha256sum "$file" | cut -d' ' -f1)
    [[ $actual == "$expected" ]] || { echo "FAIL: wrong hash for $file: $actual" >&2; exit 1; }
}
has_line() {
    local expected=$1 file=$2 line
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ $line == "$expected" ]] && return 0
    done < "$file"
    return 1
}
check_hash baba99929487b005bb9b168acfd852550055f22e5f1059c9032765209bb185e5 "$game_dir/dinput8.dll"
check_hash 1c58d3540d2c562d8da0ae12feab0564e84f5be4ad8d6de70d84990b2d033e48 "$game_dir/scripts/EaglePatchAC1.asi"
has_line 'DisableXInputPatch=0' "$game_dir/scripts/EaglePatchAC1.ini"
has_line 'PS3Controls=0' "$game_dir/scripts/EaglePatchAC1.ini"
has_line 'Multisampling=2' "$config"
has_line 'PostFX=0' "$config"
[[ $(steam_launch_options "$(steam_localconfig "$steam_root")" 15100) == "$expected_options" ]] || {
    echo 'FAIL: Steam launch options differ from the recommended complete line.' >&2; exit 1;
}
command -v mangohud >/dev/null || { echo 'FAIL: MangoHud is not installed.' >&2; exit 1; }
[[ -e /usr/lib32/mangohud/libMangoHud.so || -e /usr/lib/i386-linux-gnu/mangohud/libMangoHud.so || -e /usr/lib/mangohud/lib32/libMangoHud.so ]] || {
    echo 'FAIL: a 32-bit MangoHud library was not found.' >&2; exit 1;
}
echo 'PASS: AC1 EaglePatch, modern XInput profile, 4x MSAA, blur removal, and hidden 60 FPS cap are configured.'
