#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
compatdata=$(steam_app_compatdata_dir "$steam_root" 277590)
config="$compatdata/pfx/drive_c/users/steamuser/Documents/Assassin's Creed Freedom Cry/Assassin4.ini"

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
    'AntiAliasingMode=2' 'VSync=1' 'EnvironmentQuality=4' \
    'TextureQuality=2' 'ShadowQuality=3' 'ReflectionQuality=2' \
    'GodRays=2' 'MotionBlur=0' 'SSAO=3' 'UseVolumetricFog=1'; do
    has_line "$line"
done
launch_options=$(steam_launch_options "$(steam_localconfig "$steam_root")" 277590)
[[ -z $launch_options || $launch_options == '%command%' ]] || {
    echo 'FAIL: Steam launch options are not the stock command.' >&2
    exit 1
}
echo 'PASS: Freedom Cry maximum-quality, sharp-AA, motion-blur-free profile is configured.'
