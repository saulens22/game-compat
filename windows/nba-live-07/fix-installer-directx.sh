#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=nba-live-07
redist_name=directx_Jun2010_redist.exe
redist_url='https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe'
redist_sha=8746ee1a84a083a90e37899d71d50d5c7c015e69688a466aa80447f011780c0d

[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }
bottle=$($bottles path "$bottle_name")
directx="$bottle/drive_c/Install/NBA-Live-07/DirectX"
[[ -d $directx ]] || {
    echo 'Copy the complete installation files to C:\Install\NBA-Live-07 first.' >&2
    exit 1
}

for proc in /proc/[0-9]*; do
    [[ -r $proc/environ ]] || continue
    if (tr '\0' '\n' <"$proc/environ" 2>/dev/null || true) |
       grep -Fqx "WINEPREFIX=$bottle"; then
        echo 'Close the NBA Live 07 installer and stop this bottle before applying the fix.' >&2
        exit 1
    fi
done

cache=${XDG_CACHE_HOME:-$HOME/.cache}/game-compat/nba-live-07
archive="$cache/$redist_name"
backup="$directx/game-compat-original"
mkdir -p "$cache" "$backup"
stage=$(mktemp -d "$cache/extract.XXXXXX")
trap 'find "$stage" -type f -delete 2>/dev/null || true; rmdir "$stage" 2>/dev/null || true' EXIT

if [[ ! -f $archive ]]; then
    curl -fL --retry 3 -o "$archive.part" "$redist_url"
    mv "$archive.part" "$archive"
fi
actual=$(sha256sum "$archive" | awk '{print $1}')
[[ $actual == "$redist_sha" ]] || {
    printf 'Microsoft DirectX redistributable checksum mismatch.\nExpected: %s\nActual:   %s\n' "$redist_sha" "$actual" >&2
    exit 1
}

cabextract -q -d "$stage" -F DSETUP.dll -F dsetup32.dll -F DXSETUP.exe "$archive"
for source_name in DSETUP.dll dsetup32.dll DXSETUP.exe; do
    target_name=$source_name
    [[ $source_name == DXSETUP.exe ]] && target_name=dxsetup.exe
    [[ -f $stage/$source_name ]] || { echo "Missing $source_name in Microsoft archive." >&2; exit 1; }
    [[ -f $directx/$target_name ]] || { echo "Missing installer file: $target_name" >&2; exit 1; }
    if [[ ! -f $backup/$target_name ]]; then
        cp -a "$directx/$target_name" "$backup/$target_name"
    fi
    install -m 0644 "$stage/$source_name" "$directx/$target_name"
done

printf '%s\n' \
  'Installer DirectX engine updated.' \
  'The original three files are preserved in DirectX\game-compat-original.' \
  'Run the normal game installer now.'
