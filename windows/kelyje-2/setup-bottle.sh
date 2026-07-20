#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
expected_media=9b80360c004bb5eb4aab3de6aa27e76b060867a796895de5bc8ce5ec8957b5b1

[[ $# -eq 1 ]] || { echo "Usage: $0 /path/to/kelyje-2-source-file" >&2; exit 2; }
media=$(realpath -- "$1")
[[ -f $media ]] || { echo "Source file not found: $media" >&2; exit 1; }
[[ $(sha256sum "$media" | awk '{print $1}') == "$expected_media" ]] || {
    echo 'This is not the verified Lithuanian Kelyje II 7.3 source file.' >&2; exit 1
}

"$bottles" ensure kelyje-2 win32 gaming
bottle=$("$bottles" path kelyje-2)
game="$bottle/drive_c/Games/Kelyje2"
if [[ -e $game/RigNRoll.exe ]]; then
    echo "An installation already exists in bottle kelyje-2; refusing to overwrite it." >&2
    echo 'Use configure-fixes.sh for an existing verified installation.' >&2
    exit 1
fi
mkdir -p "$game"
bsdtar -xf "$media" -C "$game"

echo 'The original Indeo setup will open. Complete it, then dismiss any legacy'
echo 'self-registration warning; configure-fixes.sh verifies the decoder itself.'
"$bottles" run-exe kelyje-2 "$game/iv5setup.exe"
"$case_dir/configure-fixes.sh" "$media"
"$case_dir/install-d2gi.sh"
if ! "$bottles" programs kelyje-2 | grep -Fxq -- '- Kelyje 2'; then
    "$bottles" add kelyje-2 'Kelyje 2' 'C:\Games\Kelyje2\RigNRoll.exe'
fi
"$case_dir/verify-install.sh"
echo "Setup complete. Launch with: $case_dir/launch.sh"
