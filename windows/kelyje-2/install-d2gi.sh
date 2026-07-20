#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path kelyje-2)
game="$bottle/drive_c/Games/Kelyje2"
cache="$case_dir/tool-downloads/d2gi-v0.5"
archive="$cache/D2GI_v0.5.zip"
url='https://github.com/REDPOWAR/D2GI/releases/download/v0.5/D2GI_v0.5.zip'
expected=b91489288ff09fe61a54c82875152fb04d77ad1a34f467d8f85b2451d531777e

[[ -f $game/RigNRoll.exe ]] || { echo "Installed game not found: $game" >&2; exit 1; }
mkdir -p "$cache" "$case_dir/configs/d2gi-backup"
if [[ ! -f $archive ]]; then curl -fL --retry 3 -o "$archive" "$url"; fi
actual=$(sha256sum "$archive" | awk '{print $1}')
[[ $actual == "$expected" ]] || { echo "D2GI checksum mismatch: $actual" >&2; exit 1; }

for name in ddraw.dll d2gi.ini D2GI-LICENSE.txt; do
    if [[ -e $game/$name && ! -e $case_dir/configs/d2gi-backup/$name ]]; then
        cp -a "$game/$name" "$case_dir/configs/d2gi-backup/$name"
    fi
done
unzip -jo "$archive" ddraw.dll d2gi.ini D2GI-LICENSE.txt -d "$game"
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b kelyje-2 --env-var 'WINEDLLOVERRIDES=ir50_32=n,b;ddraw=n,b'
echo 'PASS: D2GI v0.5 installed with dynamic resolution, borderless mode, VSync and UI/mirror fixes.'
