#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec "$case_dir/../../skills/steam-proton-diagnostic/scripts/steam-session.sh" \
    --unit mk11-steam-session.service "$@"
