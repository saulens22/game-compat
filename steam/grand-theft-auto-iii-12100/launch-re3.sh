#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "$0")" && pwd)
runtime="$case_dir/runtime/re3"
log_dir="$case_dir/logs"
mkdir -p "$log_dir"

[[ -x $runtime/re3 ]] || { echo "Missing native re3 runtime." >&2; exit 1; }
[[ -e $runtime/models/gta3.img ]] || { echo "Local assets are not staged." >&2; exit 1; }

{
    printf 'timestamp=%s\n' "$(date --iso-8601=seconds)"
    printf 'cwd=%s\n' "$runtime"
    printf 'executable=%s\n' "$runtime/re3"
    printf 'steam_app_id=%s\n' "${SteamAppId:-${STEAM_APP_ID:-unknown}}"
    printf 'arguments='; printf '%q ' "$@"; printf '\n'
} >> "$log_dir/launcher.log"

cd "$runtime"
exec "$runtime/re3"
