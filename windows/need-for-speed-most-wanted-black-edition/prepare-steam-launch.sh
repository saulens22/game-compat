#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)

# 0xffffffff tells the current Widescreen Fix to select the active desktop.
# The game writes a concrete resolution back on exit, so reset this before each
# launch to remain portable across monitor changes. Edit the inactive plain-text
# prefix registry directly: starting a helper Wine server here can outlive the
# game and leave Steam's non-Steam shortcut stuck in the Running state.
exec "$repo_dir/wine-reg-set-dword.sh" \
    nfsmw-black-edition \
    'Software\EA Games\Need for Speed Most Wanted' \
    g_RacingResolution ffffffff
