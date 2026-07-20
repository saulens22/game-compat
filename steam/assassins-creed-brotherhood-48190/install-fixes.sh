#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

app_id=48190
runtime="$case_dir/runtime"
steam_root=$(resolve_steam_root)
compatdata=$(steam_app_compatdata_dir "$steam_root" "$app_id")
config="$compatdata/pfx/drive_c/users/steamuser/Saved Games/Assassin's Creed Brotherhood/ACBrotherhood.ini"
save_dir=$(dirname -- "$config")/SAVES
backup="$runtime/backups/original/ACBrotherhood.ini"

pgrep -f '[A]CBSP\.exe' >/dev/null && {
    echo "Assassin's Creed Brotherhood is running. Exit it before setup." >&2
    exit 1
}
[[ -f $config ]] || {
    echo 'Run Brotherhood once so ACBrotherhood.ini exists, then exit it.' >&2
    exit 1
}
mkdir -p "$runtime/backups/original" "$save_dir"
[[ -e $backup ]] || cp -a -- "$config" "$backup"

CONFIG=$config perl -i -pe '
    s/^MultiSampleType=.*/MultiSampleType=8/;
    s/^VSync=.*/VSync=0/;
    s/^EnvironmentQuality=.*/EnvironmentQuality=5/;
    s/^TextureQuality=.*/TextureQuality=2/;
    s/^ShadowQuality=.*/ShadowQuality=4/;
    s/^ReflectionQuality=.*/ReflectionQuality=3/;
    s/^CharacterQuality=.*/CharacterQuality=4/;
    s/^PostFX=.*/PostFX=0/;
    s/^SelectedInput=.*/SelectedInput=Controller (XBOX 360 For Windows)/;
' "$config"
printf 'v1\n' > "$runtime/installed-version"
echo 'Configured maximum native quality, motion-blur-free PostFX, native Xbox input, and the required SAVES directory.'
