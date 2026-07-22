#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path nba-live-07)
fail=0

if rg -q '^Arch: win64$' "$bottle/bottle.yml" &&
   rg -q '^Runner: ge-proton11-1$' "$bottle/bottle.yml" &&
   rg -q '^    sync: ntsync$' "$bottle/bottle.yml"; then
    echo 'PASS: canonical win64 GE-Proton bottle with NT sync'
else
    echo 'FAIL: expected win64, GE-Proton 11-1 and NT sync' >&2
    fail=1
fi

mapfile -d '' executables < <(find "$bottle/drive_c" -type f -path '*/EA SPORTS/NBA LIVE 07/nbalive07.exe' -print0)
if [[ ${#executables[@]} -eq 1 ]]; then
    echo 'PASS: exactly one installed NBA Live 07 executable'
    file "${executables[0]}"
    sha256sum "${executables[0]}"
else
    echo "FAIL: expected one installed nbalive07.exe, found ${#executables[@]}" >&2
    fail=1
fi

for architecture in system32 syswow64; do
    for dll in libvkd3d-1.dll libvkd3d-shader-1.dll libvkd3d-utils-1.dll; do
        if [[ -f $bottle/drive_c/windows/$architecture/$dll ]]; then
            echo "PASS: GE-Proton WineD3D support: $architecture/$dll"
        else
            echo "FAIL: missing GE-Proton WineD3D support: $architecture/$dll" >&2
            fail=1
        fi
    done
done

game=${executables[0]%/*}
for relative in d3d9.dll oledlg.dll main.ini plugins/loader.ini plugins/Resolution.asi; do
    if [[ -f $game/$relative ]]; then
        echo "PASS: widescreen stack: $relative"
    else
        echo "INFO: widescreen stack is not installed: $relative"
    fi
done
if [[ -f $game/plugins/Resolution.asi ]]; then
    if rg -q '^[[:space:]]*WINEDLLOVERRIDES: d3d9=n,b$' "$bottle/bottle.yml"; then
        echo 'PASS: local D3D9 ASI loader is preferred'
    else
        echo 'FAIL: local D3D9 ASI loader override is missing' >&2
        fail=1
    fi
fi
exit "$fail"
