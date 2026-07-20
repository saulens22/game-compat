#!/usr/bin/env bash

game_compat_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -f $game_compat_root/.env ]]; then
    # This is a trusted, local, user-maintained shell environment file.
    # shellcheck disable=SC1091
    set -a; source "$game_compat_root/.env"; set +a
fi
: "${EMULATION_ROOT:=${XDG_DATA_HOME:-$HOME/.local/share}/game-compat/emulation}"
export EMULATION_ROOT
