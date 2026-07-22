#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
if [[ -f "$repo_dir/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$repo_dir/.env"
    set +a
fi

usage() {
    echo "Usage: $0 GAME_DIRECTORY FILE_GLOB" >&2
    exit 2
}

[[ $# -eq 2 ]] || usage
game_directory=$1
file_glob=$2
emulation_root=${EMULATION_ROOT:-"$HOME/Games/Emulation"}
ryujinx_bin=${RYUJINX_BIN:-ryujinx}
ryujinx_config=${RYUJINX_CONFIG:-"$HOME/.config/Ryujinx/Config.json"}

command -v "$ryujinx_bin" >/dev/null || {
    echo "Ryujinx was not found. Set RYUJINX_BIN or install Ryujinx." >&2
    exit 1
}
command -v jq >/dev/null || {
    echo "jq is required to enable fullscreen safely." >&2
    exit 1
}
if pgrep -x ryujinx >/dev/null; then
    echo "Ryujinx is already running. Close it before starting another game." >&2
    exit 1
fi

rom_dir="$emulation_root/roms/switch/$game_directory"
mapfile -d '' roms < <(find "$rom_dir" -maxdepth 1 -type f -name "$file_glob" -print0 2>/dev/null)
if [[ ${#roms[@]} -ne 1 ]]; then
    echo "Expected exactly one matching game file in: $rom_dir" >&2
    echo "Pattern: $file_glob; found: ${#roms[@]}" >&2
    exit 1
fi

[[ -f "$ryujinx_config" ]] || {
    echo "Ryujinx configuration was not found: $ryujinx_config" >&2
    echo "Start Ryujinx once, close it, and retry." >&2
    exit 1
}

backup_dir="$repo_dir/_work/ryujinx-config-backups"
mkdir -p "$backup_dir"
cp -a "$ryujinx_config" "$backup_dir/Config.$(date +%Y%m%d-%H%M%S).json"
temporary=$(mktemp --tmpdir="$(dirname -- "$ryujinx_config")" Config.json.XXXXXX)
trap 'rm -f -- "$temporary"' EXIT
jq '.start_fullscreen = true' "$ryujinx_config" > "$temporary"
chmod --reference="$ryujinx_config" "$temporary"
mv -f -- "$temporary" "$ryujinx_config"
trap - EXIT

exec "$ryujinx_bin" "${roms[0]}"
