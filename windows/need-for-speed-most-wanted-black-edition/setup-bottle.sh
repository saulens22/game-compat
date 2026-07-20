#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)

[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }
"$repo_dir/bottles-game.sh" ensure nfsmw-black-edition win64 gaming

cat <<'EOF'
Bottle ready. In Bottles:
1. Copy your complete installer set into C:\Install\NFSMW-Black-Edition.
2. Run its installer inside the nfsmw-black-edition bottle.
3. Install the game, but skip bundled DirectX/Visual C++ installers and desktop shortcuts.
4. After installation finishes, run configure-fixes.sh.

This script never accepts or copies installation files.
EOF
