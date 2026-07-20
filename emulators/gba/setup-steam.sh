#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $# -eq 1 ]] || { echo "Usage: $0 /path/to/your-clean-fire-red-1.0.gba" >&2; exit 2; }
"$case_dir/patch-rom.py" "$1"
"$case_dir/verify-install.sh"
echo "Launch with: $case_dir/launch-steam.sh"
