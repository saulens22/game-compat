#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

app_id=33230
eagle_version=v1.1
eagle_sha=4d60fe65bd1a5859155a05284d52703788ea3d036b9f9300487f80b0bbec3266
loader_version=v4.68
loader_sha=7517c7d5bd8c475f18e6545b7998df379eed6e2e0a19fcd2139669152f9bcddb
runtime="$case_dir/runtime"
downloads="$runtime/downloads/$eagle_version"
originals="$runtime/backups/original"
steam_root=$(resolve_steam_root)
game_dir=$(steam_app_install_dir "$steam_root" "$app_id")
compatdata=$(steam_app_compatdata_dir "$steam_root" "$app_id")
config="$compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Ubisoft/Assassin's Creed 2/Assassin2.ini"

for command in curl unzip sha256sum perl install; do
    command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
pgrep -f 'AssassinsCreedIIGame\.exe' >/dev/null && {
    echo "Assassin's Creed II is running. Exit the game before installing fixes." >&2
    exit 1
}
[[ -f $config ]] || { echo 'Run the game once so Assassin2.ini exists, then exit it.' >&2; exit 1; }
exe_sha=$(sha256sum "$game_dir/AssassinsCreedIIGame.exe" | cut -d' ' -f1)
[[ $exe_sha == a4ba454b0e2a9190a42db631574b694cc0dbdcec750106c1b0364b70a6e4d17e ]] || {
    echo "Untested AC2 executable: $exe_sha" >&2; exit 1;
}

mkdir -p "$downloads/eagle" "$downloads/loader" "$originals"
curl -fL --retry 3 -o "$downloads/EaglePatchAC2.zip" \
    "https://github.com/Sergeanur/EaglePatch/releases/download/$eagle_version/EaglePatchAC2.zip"
curl -fL --retry 3 -o "$downloads/Ultimate-ASI-Loader.zip" \
    "https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/$loader_version/Ultimate-ASI-Loader.zip"
printf '%s  %s\n' "$eagle_sha" "$downloads/EaglePatchAC2.zip" | sha256sum -c -
printf '%s  %s\n' "$loader_sha" "$downloads/Ultimate-ASI-Loader.zip" | sha256sum -c -
unzip -oq "$downloads/EaglePatchAC2.zip" -d "$downloads/eagle"
unzip -oq "$downloads/Ultimate-ASI-Loader.zip" -d "$downloads/loader"

if [[ ! -e $originals/.captured ]]; then
    [[ ! -e $game_dir/dinput8.dll ]] || cp -a -- "$game_dir/dinput8.dll" "$originals/dinput8.dll"
    [[ ! -e $game_dir/scripts/EaglePatchAC2.asi ]] || cp -a -- "$game_dir/scripts/EaglePatchAC2.asi" "$originals/EaglePatchAC2.asi"
    [[ ! -e $game_dir/scripts/EaglePatchAC2.ini ]] || cp -a -- "$game_dir/scripts/EaglePatchAC2.ini" "$originals/EaglePatchAC2.ini"
    cp -a -- "$config" "$originals/Assassin2.ini"
    : > "$originals/.captured"
fi

install -Dm755 "$downloads/loader/dinput8.dll" "$game_dir/dinput8.dll"
install -Dm755 "$downloads/eagle/EaglePatchAC2.asi" "$game_dir/scripts/EaglePatchAC2.asi"
install -Dm644 "$downloads/eagle/EaglePatchAC2.ini" "$game_dir/scripts/EaglePatchAC2.ini"
PATCH_INI="$game_dir/scripts/EaglePatchAC2.ini" perl -i -pe \
    's/^ImproveDrawDistance=.*/ImproveDrawDistance=0/' "$game_dir/scripts/EaglePatchAC2.ini"
CONFIG=$config perl -i -pe 's/^MultiSampleType=.*/MultiSampleType=8/' "$config"
printf 'v1\n' > "$runtime/installed-version"
echo 'Installed EaglePatchAC2 v1.1 with stable draw distance and the 8x MSAA profile.'
