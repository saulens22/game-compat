#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
game_dir=$(steam_app_install_dir "$steam_root" 33230)
compatdata=$(steam_app_compatdata_dir "$steam_root" 33230)
config="$compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Ubisoft/Assassin's Creed 2/Assassin2.ini"
expected_options='WINEDLLOVERRIDES="dinput8=n,b" %command%'

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
check_hash 3c258780f641fc54406a162dba6fa28e35aab20a179fc2d47a796448133e7554 "$game_dir/scripts/EaglePatchAC2.asi"
has_line 'DisableXInputPatch=0' "$game_dir/scripts/EaglePatchAC2.ini"
has_line 'PS3Controls=0' "$game_dir/scripts/EaglePatchAC2.ini"
has_line 'ImproveShadowMapResolution=1' "$game_dir/scripts/EaglePatchAC2.ini"
has_line 'ImproveDrawDistance=0' "$game_dir/scripts/EaglePatchAC2.ini"
has_line 'MultiSampleType=8' "$config"
has_line 'EnvironmentQuality=3' "$config"
has_line 'TextureQuality=2' "$config"
has_line 'ShadowQuality=2' "$config"
has_line 'ReflectionQuality=2' "$config"
has_line 'CharacterQuality=2' "$config"
[[ $(steam_launch_options "$(steam_localconfig "$steam_root")" 33230) == "$expected_options" ]] || {
    echo 'FAIL: Steam launch options differ from the recommended complete line.' >&2; exit 1;
}
echo 'PASS: AC2 EaglePatch, XInput fixes, 4096 shadows, 8x MSAA, and stable draw-distance profile are configured.'
