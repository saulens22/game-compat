#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle_name=nba-live-07
update_archive_sha=87e20d9831c935946dadfc1aa5691fa16ba3b6a0eec7a3ca9b7398d97ab5e458
fixed_archive_sha=988d7695fa6e0f069ade5fd6ea6bd035d4a69403a8bfb909e9760fb9d4ce18f9
original_exe_sha=b8955dc4c7e146a678159650c3543209671e9bdeb395d368933d1b0eab1361fe
official_11_exe_sha=5d1f16ebd0c10e291355e467e4dcfe454e02d506b681928c4d01a7487cc5bc74
fixed_11_exe_sha=2f2fcbfb1fe6ee513cddbe2c0d50e0a1ee6aa3a30db8bad4ed58e3bce1597216

[[ $# -eq 2 ]] || {
    echo "Usage: $0 /path/to/nbalive_sd_patch_na.zip /path/to/NBALive2007v1.1NoDVDFixedexeEng.7z" >&2
    exit 2
}
update_archive=$1
fixed_archive=$2
[[ -f $update_archive && -f $fixed_archive ]] || { echo 'One or both update archives are missing.' >&2; exit 1; }

check_sha() {
    local expected=$1 file=$2 actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'Checksum mismatch: %s\nExpected: %s\nActual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 1
    }
}
check_sha "$update_archive_sha" "$update_archive"
check_sha "$fixed_archive_sha" "$fixed_archive"

bottle=$("$repo_dir/bottles-game.sh" path "$bottle_name")
game="$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07"
exe="$game/nbalive07.exe"
[[ -f $exe ]] || { echo 'NBA Live 07 is not installed in the expected bottle.' >&2; exit 1; }
current=$(sha256sum "$exe" | awk '{print $1}')
if [[ $current == "$fixed_11_exe_sha" ]]; then
    echo 'Official 1.1 update and matching fixed executable are already installed.'
    exit 0
fi
[[ $current == "$original_exe_sha" ]] || {
    printf 'The installed executable is not the untouched supported build.\nExpected: %s\nActual:   %s\nRestore it before applying the official update.\n' "$original_exe_sha" "$current" >&2
    exit 1
}

backup="$case_dir/configs/pre-official-update"
mkdir -p "$backup"
[[ -f $backup/nbalive07-original.exe ]] || cp -a "$exe" "$backup/nbalive07-original.exe"
player_data="$bottle/drive_c/users/steamuser/Documents/NBA LIVE 07"
if [[ -d $player_data && ! -e $backup/player-data ]]; then
    cp -a "$player_data" "$backup/player-data"
fi

cache=${XDG_CACHE_HOME:-$HOME/.cache}/game-compat/nba-live-07/official-update
stage=$(mktemp -d "$cache.XXXXXX")
trap 'find "$stage" -type f -delete 2>/dev/null || true; find "$stage" -depth -type d -empty -delete 2>/dev/null || true' EXIT
mkdir -p "$stage/update" "$stage/fixed"
unzip -q "$update_archive" -d "$stage/update"
bsdtar -xf "$fixed_archive" -C "$stage/fixed"
updater=$(find "$stage/update" -type f -name 'NBA07_SD_PATCH-NA_001.exe' -print -quit)
fixed=$(find "$stage/fixed" -type f -iname 'nbalive07.exe' -print -quit)
[[ -f $updater && -f $fixed ]] || { echo 'An update archive has an unexpected layout.' >&2; exit 1; }
check_sha "$fixed_11_exe_sha" "$fixed"

# A root-level path avoids an old Bottles CLI quoting bug with Windows paths
# containing directories. The EA updater remains interactive and must finish
# successfully before this script will replace the executable.
cp -a "$updater" "$bottle/drive_c/nba07patch.exe"
echo 'Complete the official EA updater window. Do not cancel it.'
"$repo_dir/bottles-game.sh" run-exe "$bottle_name" 'C:\nba07patch.exe'

current=$(sha256sum "$exe" | awk '{print $1}')
[[ $current == "$official_11_exe_sha" ]] || {
    printf 'Official update verification failed. The fixed executable was not installed.\nExpected patched executable: %s\nActual:                     %s\n' "$official_11_exe_sha" "$current" >&2
    exit 1
}
cp -a "$exe" "$backup/nbalive07-official-1.1.exe"
install -m 0755 "$fixed" "$exe"
check_sha "$fixed_11_exe_sha" "$exe"
echo 'Official 1.1 update and checksum-matched fixed executable installed.'
