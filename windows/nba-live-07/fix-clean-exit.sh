#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path nba-live-07)
exe=${NBA_LIVE_07_EXE:-"$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07/nbalive07.exe"}
backup=${NBA_LIVE_07_EXIT_BACKUP:-"$exe.game-compat-exit-backup"}
offset=$((0x1378))
stock_hash=2f2fcbfb1fe6ee513cddbe2c0d50e0a1ee6aa3a30db8bad4ed58e3bce1597216
stock_bytes=7510
patched_bytes=9090

usage() {
    cat <<'EOF'
Usage: fix-clean-exit.sh [apply|status|rollback]

Patches NBA Live 07's normal CRT shutdown branch to use the executable's
existing TerminateProcess path after the main game loop returns. This avoids
the game's known shutdown deadlock without an external process killer.

Environment:
  NBA_LIVE_07_EXE          Override the executable path.
  NBA_LIVE_07_EXIT_BACKUP  Override the backup path.
EOF
}

bytes_at_offset() {
    od -An -tx1 -N2 -j "$offset" "$1" | tr -d ' \n'
}

require_stopped() {
    if pgrep -f '[n]balive07\.exe' >/dev/null; then
        echo 'NBA Live 07 is running. Exit it before changing the executable.' >&2
        exit 1
    fi
}

action=${1:-status}
case "$action" in
    status)
        [[ -f $exe ]] || { echo "Executable not found: $exe" >&2; exit 1; }
        current=$(bytes_at_offset "$exe")
        case "$current" in
            "$stock_bytes") echo 'Clean-exit patch: not applied' ;;
            "$patched_bytes") echo 'Clean-exit patch: applied' ;;
            *) echo "Clean-exit patch: unknown executable bytes ($current)" >&2; exit 2 ;;
        esac
        ;;
    apply)
        require_stopped
        [[ -f $exe ]] || { echo "Executable not found: $exe" >&2; exit 1; }
        current=$(bytes_at_offset "$exe")
        if [[ $current == "$patched_bytes" ]]; then
            echo 'Clean-exit patch is already applied.'
            exit 0
        fi
        [[ $current == "$stock_bytes" ]] || {
            echo "Refusing to patch unknown bytes at offset 0x1378: $current" >&2
            exit 2
        }
        hash=$(sha256sum "$exe" | awk '{print $1}')
        [[ $hash == "$stock_hash" ]] || {
            echo "Refusing to patch an unverified executable: $hash" >&2
            exit 2
        }
        [[ ! -e $backup ]] || {
            echo "Backup already exists; refusing to overwrite it: $backup" >&2
            exit 2
        }
        cp -a -- "$exe" "$backup"
        printf '\220\220' | dd of="$exe" bs=1 seek="$offset" conv=notrunc status=none
        [[ $(bytes_at_offset "$exe") == "$patched_bytes" ]] || {
            cp -a -- "$backup" "$exe"
            echo 'Patch verification failed; restored the backup.' >&2
            exit 1
        }
        echo 'Clean-exit patch applied. The original executable is backed up beside it.'
        ;;
    rollback)
        require_stopped
        [[ -f $backup ]] || { echo "Backup not found: $backup" >&2; exit 1; }
        hash=$(sha256sum "$backup" | awk '{print $1}')
        [[ $hash == "$stock_hash" ]] || {
            echo "Refusing to restore an unverified backup: $hash" >&2
            exit 2
        }
        cp -a -- "$backup" "$exe"
        rm -- "$backup"
        echo 'Original executable restored.'
        ;;
    -h|--help) usage ;;
    *) usage >&2; exit 2 ;;
esac
