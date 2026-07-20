#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
compatdata=$(steam_app_compatdata_dir "$steam_root" 48190)
config="$compatdata/pfx/drive_c/users/steamuser/Saved Games/Assassin's Creed Brotherhood/ACBrotherhood.ini"
expected='PROTON_PREFER_SDL=1 MANGOHUD_CONFIG=fps_limit=60,no_display mangohud %command%'

has_line() {
    local expected_line=$1 line
    [[ -f $config ]] || { echo "FAIL: missing $config" >&2; exit 1; }
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ $line == "$expected_line" ]] && return 0
    done < "$config"
    echo "FAIL: missing config line: $expected_line" >&2
    exit 1
}
for line in \
    'MultiSampleType=8' 'VSync=0' 'EnvironmentQuality=5' \
    'TextureQuality=2' 'ShadowQuality=4' 'ReflectionQuality=3' \
    'CharacterQuality=4' 'PostFX=0' \
    'SelectedInput=Controller (XBOX 360 For Windows)'; do
    has_line "$line"
done
[[ -d $(dirname -- "$config")/SAVES ]] || { echo 'FAIL: SAVES directory is missing.' >&2; exit 1; }
[[ $(steam_launch_options "$(steam_localconfig "$steam_root")" 48190) == "$expected" ]] || {
    echo 'FAIL: Steam launch options differ from the recommended complete line.' >&2
    exit 1
}
command -v mangohud >/dev/null || { echo 'FAIL: MangoHud is not installed.' >&2; exit 1; }
echo 'PASS: Brotherhood native controller, maximum quality, PostFX, save path, and 60 FPS launch profile are configured.'
