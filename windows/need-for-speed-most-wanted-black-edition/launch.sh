#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle_name=nfsmw-black-edition

# Reset display selection without starting a helper Wine server. A helper
# server can survive the game and keep a calling frontend in a Running state.
"$repo_dir/wine-reg-set-dword.sh" \
    "$bottle_name" \
    'Software\EA Games\Need for Speed Most Wanted' \
    g_RacingResolution ffffffff

exec "$repo_dir/bottles-game.sh" run \
    "$bottle_name" 'Need for Speed Most Wanted Black Edition' "$@"
