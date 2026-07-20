#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=kelyje-2
program_name='Kelyje 2'
bottle=$("$bottles" path "$bottle_name")
[[ -f $bottle/bottle.yml ]] || { echo "Bottle does not exist: $bottle_name" >&2; exit 1; }
"$bottles" run "$bottle_name" "$program_name" "$@"
