#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=nba-live-07
runner_name=ge-proton11-1

[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }
bottle=$($bottles path "$bottle_name")
game="$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07"
[[ -f $game/nbalive07.exe ]] || {
    echo 'Install NBA Live 07 inside the bottle before configuring its runtime.' >&2
    exit 1
}

flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --runner "$runner_name"
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --vkd3d vkd3d-proton-3.0.1
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --params 'sync:ntsync'

# Install optional DirectX 9 runtime DLLs through the Bottles Winetricks path.
"$repo_dir/bottles-winetricks.sh" "$bottle_name" \
    d3dx9 d3dcompiler_43 d3dcompiler_47

# Bottles can retain WineD3D from the runner used when the bottle was created
# after switching runners. GE-Proton's WineD3D imports these six support DLLs.
# Restore them from this selected runner's own default-prefix template, never
# from another game bottle.
bottles_data=$(dirname "$(dirname "$bottle")")
template="$bottles_data/runners/$runner_name/files/share/default_pfx/drive_c/windows"
for architecture in system32 syswow64; do
    for dll in libvkd3d-1.dll libvkd3d-shader-1.dll libvkd3d-utils-1.dll; do
        [[ -f $template/$architecture/$dll ]] || {
            echo "Selected runner is missing $architecture/$dll" >&2
            exit 1
        }
        install -m 0644 "$template/$architecture/$dll" \
            "$bottle/drive_c/windows/$architecture/$dll"
    done
done

if ! "$bottles" programs "$bottle_name" | grep -Fxq -- '- NBA Live 07'; then
    "$bottles" add "$bottle_name" 'NBA Live 07' \
        'C:\Program Files (x86)\EA SPORTS\NBA LIVE 07\nbalive07.exe'
fi
"$case_dir/verify-install.sh"
