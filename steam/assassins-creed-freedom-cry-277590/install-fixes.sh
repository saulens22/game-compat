#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

app_id=277590
runtime="$case_dir/runtime"
steam_root=$(resolve_steam_root)
compatdata=$(steam_app_compatdata_dir "$steam_root" "$app_id")
config="$compatdata/pfx/drive_c/users/steamuser/Documents/Assassin's Creed Freedom Cry/Assassin4.ini"
backup="$runtime/backups/original/Assassin4.ini"

pgrep -f '[A]CFC\.exe' >/dev/null && {
    echo "Assassin's Creed Freedom Cry is running. Exit it before setup." >&2
    exit 1
}
[[ -f $config ]] || {
    echo 'Run Freedom Cry once so Assassin4.ini exists, then exit it.' >&2
    exit 1
}
mkdir -p "$runtime/backups/original"
[[ -e $backup ]] || cp -a -- "$config" "$backup"

CONFIG=$config perl -i -pe '
    s/^AntiAliasingMode=.*/AntiAliasingMode=2/;
    s/^VSync=.*/VSync=1/;
    s/^EnvironmentQuality=.*/EnvironmentQuality=4/;
    s/^TextureQuality=.*/TextureQuality=2/;
    s/^ShadowQuality=.*/ShadowQuality=3/;
    s/^ReflectionQuality=.*/ReflectionQuality=2/;
    s/^GodRays=.*/GodRays=2/;
    s/^MotionBlur=.*/MotionBlur=0/;
    s/^SSAO=.*/SSAO=3/;
    s/^UseVolumetricFog=.*/UseVolumetricFog=1/;
' "$config"
printf 'v1\n' > "$runtime/installed-version"
echo 'Configured maximum native quality, sharp SMAA, HBAO+ High, and motion blur off.'
