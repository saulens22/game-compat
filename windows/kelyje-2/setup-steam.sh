#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
exec "$repo_dir/run-python-tool.sh" add-steam-shortcut.py 'Kelyje II' "$case_dir/launch.sh" "$@"
