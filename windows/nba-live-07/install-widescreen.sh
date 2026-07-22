#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=nba-live-07
loader_md5=25bd9be0efd9dddba77655b2568c2d80
widescreen_sha=68648f15b15cfe6a6af8303b18e65fe97889047ed6f6f84c75a8c643764a3504
widescreen_url='https://github.com/muratcansarkalkan/NBALiveResolution/releases/download/v1.04/NBA_WS_Resolution_v1.04.7z'
fixed_exe_sha=2f2fcbfb1fe6ee513cddbe2c0d50e0a1ee6aa3a30db8bad4ed58e3bce1597216

[[ $# -eq 1 ]] || {
    echo "Usage: $0 /path/to/FIFAM-ASI-LOADER-1_0_5_0-D3D9.zip" >&2
    exit 2
}
loader=$1
[[ -f $loader ]] || { echo "Loader archive not found: $loader" >&2; exit 1; }
actual=$(md5sum "$loader" | awk '{print $1}')
[[ $actual == "$loader_md5" ]] || {
    printf 'FIFAM ASI Loader checksum mismatch.\nExpected: %s\nActual:   %s\n' "$loader_md5" "$actual" >&2
    exit 1
}

bottle=$($bottles path "$bottle_name")
game="$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07"
[[ -f $game/nbalive07.exe ]] || { echo 'NBA Live 07 is not installed.' >&2; exit 1; }
actual=$(sha256sum "$game/nbalive07.exe" | awk '{print $1}')
[[ $actual == "$fixed_exe_sha" ]] || {
    printf 'Widescreen support is executable-specific.\nExpected: %s\nActual:   %s\n' "$fixed_exe_sha" "$actual" >&2
    exit 1
}

cache=${XDG_CACHE_HOME:-$HOME/.cache}/game-compat/nba-live-07
widescreen="$cache/NBA_WS_Resolution_v1.04.7z"
mkdir -p "$cache"
if [[ ! -f $widescreen ]]; then
    curl -fL --retry 3 -o "$widescreen.part" "$widescreen_url"
    mv "$widescreen.part" "$widescreen"
fi
actual=$(sha256sum "$widescreen" | awk '{print $1}')
[[ $actual == "$widescreen_sha" ]] || {
    printf 'Widescreen archive checksum mismatch.\nExpected: %s\nActual:   %s\n' "$widescreen_sha" "$actual" >&2
    exit 1
}

stage=$(mktemp -d "$cache/widescreen.XXXXXX")
trap 'find "$stage" -type f -delete 2>/dev/null || true; find "$stage" -depth -type d -empty -delete 2>/dev/null || true' EXIT
unzip -q "$loader" -d "$stage/loader"
bsdtar -xf "$widescreen" -C "$stage"
loader_root=$(find "$stage/loader" -type f -name d3d9.dll -printf '%h\n' -quit)
[[ -f $loader_root/oledlg.dll && -f $loader_root/plugins/loader.ini ]] || {
    echo 'FIFAM ASI Loader archive has an unexpected layout.' >&2
    exit 1
}
[[ -f $stage/plugins/Resolution.asi && -f $stage/main.ini ]] || {
    echo 'NBA Live Resolution archive has an unexpected layout.' >&2
    exit 1
}

backup="$case_dir/configs/pre-widescreen"
mkdir -p "$backup"
for relative in d3d9.dll oledlg.dll main.ini plugins/loader.ini plugins/Resolution.asi; do
    if [[ -e $game/$relative && ! -e $backup/$relative ]]; then
        mkdir -p "$backup/$(dirname "$relative")"
        cp -a "$game/$relative" "$backup/$relative"
    fi
done

mkdir -p "$game/plugins"
install -m 0644 "$loader_root/d3d9.dll" "$game/d3d9.dll"
install -m 0644 "$loader_root/oledlg.dll" "$game/oledlg.dll"
install -m 0644 "$loader_root/plugins/loader.ini" "$game/plugins/loader.ini"
install -m 0644 "$stage/plugins/Resolution.asi" "$game/plugins/Resolution.asi"
install -m 0644 "$stage/main.ini" "$game/main.ini"
if [[ -d $stage/assets ]]; then
    mkdir -p "$game/assets"
    cp -a "$stage/assets/." "$game/assets/"
fi

# Wine must prefer the local proxy so it can load Resolution.asi, then fall
# back to the runner's D3D9 implementation.
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --env-var 'WINEDLLOVERRIDES=d3d9=n,b'

"$case_dir/prepare-launch.sh"
"$case_dir/verify-install.sh"
echo 'Widescreen support installed. Launch normally for the player test.'
