#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle_name=nfsmw-black-edition

# 0xffffffff tells the current Widescreen Fix to select the active desktop.
# This deliberately avoids assuming 4K, 1080p, a particular aspect ratio, or
# the display that happened to be connected during setup.
flatpak run --command=bottles-cli com.usebottles.bottles reg edit \
    -b "$bottle_name" \
    -k 'HKEY_CURRENT_USER\Software\EA Games\Need for Speed Most Wanted' \
    -v g_RacingResolution -d 4294967295 -t REG_DWORD

exec "$repo_dir/bottles-game.sh" run \
    "$bottle_name" 'Need for Speed Most Wanted Black Edition' "$@"
