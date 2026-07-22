#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }

"$repo_dir/bottles-game.sh" ensure nba-live-07 win64 gaming

cat <<'EOF'
Bottle ready. Next:
1. Open the nba-live-07 bottle in Bottles.
2. Copy the complete installation files into C:\Install\NBA-Live-07.
3. Run fix-installer-directx.sh before starting the installer.
4. Start the installer from Bottles and install the game normally.

This script never accepts or copies installation files.
EOF
