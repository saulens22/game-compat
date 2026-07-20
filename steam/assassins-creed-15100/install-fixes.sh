#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

app_id=15100
eagle_version=v1.1
eagle_sha=6dc496ac6b298b92fb70c3f90a34e323f77ac88e6ea97544f84e52435038aeea
loader_version=v4.68
loader_sha=7517c7d5bd8c475f18e6545b7998df379eed6e2e0a19fcd2139669152f9bcddb
runtime="$case_dir/runtime"
downloads="$runtime/downloads/$eagle_version"
originals="$runtime/backups/original"
steam_root=$(resolve_steam_root)
game_dir=$(steam_app_install_dir "$steam_root" "$app_id")
compatdata=$(steam_app_compatdata_dir "$steam_root" "$app_id")
config="$compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Ubisoft/Assassin's Creed/Assassin.ini"

for command in curl unzip sha256sum md5sum perl install; do
    command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
pgrep -f 'AssassinsCreed_(Dx9|Dx10)\.exe' >/dev/null && {
    echo "Assassin's Creed is running. Exit the game before installing fixes." >&2
    exit 1
}
[[ -f $config ]] || { echo 'Run the game once so Assassin.ini exists, then exit it.' >&2; exit 1; }

dx9_md5=$(md5sum "$game_dir/AssassinsCreed_Dx9.exe" | cut -d' ' -f1)
dx10_md5=$(md5sum "$game_dir/AssassinsCreed_Dx10.exe" | cut -d' ' -f1)
[[ $dx9_md5 == 8e72c3333743780e43bc2c34bbf625f9 ]] || { echo "Unsupported DX9 executable: $dx9_md5" >&2; exit 1; }
[[ $dx10_md5 == ca87753255e2d14b1f18bb737c643792 ]] || { echo "Unsupported DX10 executable: $dx10_md5" >&2; exit 1; }

mkdir -p "$downloads/eagle" "$downloads/loader" "$originals"
curl -fL --retry 3 -o "$downloads/EaglePatchAC1.zip" \
    "https://github.com/Sergeanur/EaglePatch/releases/download/$eagle_version/EaglePatchAC1.zip"
curl -fL --retry 3 -o "$downloads/Ultimate-ASI-Loader.zip" \
    "https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/$loader_version/Ultimate-ASI-Loader.zip"
printf '%s  %s\n' "$eagle_sha" "$downloads/EaglePatchAC1.zip" | sha256sum -c -
printf '%s  %s\n' "$loader_sha" "$downloads/Ultimate-ASI-Loader.zip" | sha256sum -c -
unzip -oq "$downloads/EaglePatchAC1.zip" -d "$downloads/eagle"
unzip -oq "$downloads/Ultimate-ASI-Loader.zip" -d "$downloads/loader"

if [[ ! -e $originals/.captured ]]; then
    [[ ! -e $game_dir/dinput8.dll ]] || cp -a -- "$game_dir/dinput8.dll" "$originals/dinput8.dll"
    [[ ! -e $game_dir/scripts/EaglePatchAC1.asi ]] || cp -a -- "$game_dir/scripts/EaglePatchAC1.asi" "$originals/EaglePatchAC1.asi"
    [[ ! -e $game_dir/scripts/EaglePatchAC1.ini ]] || cp -a -- "$game_dir/scripts/EaglePatchAC1.ini" "$originals/EaglePatchAC1.ini"
    cp -a -- "$config" "$originals/Assassin.ini"
    : > "$originals/.captured"
fi

install -Dm755 "$downloads/loader/dinput8.dll" "$game_dir/dinput8.dll"
install -Dm755 "$downloads/eagle/EaglePatchAC1.asi" "$game_dir/scripts/EaglePatchAC1.asi"
install -Dm644 "$downloads/eagle/EaglePatchAC1.ini" "$game_dir/scripts/EaglePatchAC1.ini"

CONFIG=$config perl -i -pe '
    s/^Multisampling=.*/Multisampling=2/;
    s/^PostFX=.*/PostFX=0/;
' "$config"
printf 'v1\n' > "$runtime/installed-version"
echo 'Installed EaglePatchAC1 v1.1, 4x MSAA, and the no-motion-blur profile.'
