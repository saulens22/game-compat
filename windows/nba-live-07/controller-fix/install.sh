#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
artifact="$case_dir/controller-fix/NBAControllerProfileFallback-v2.asi"
expected_exe='b5a69861faae630a4204ee06e3ade8b70ebea48ff3f7f7629a47b8aa6547b039'

usage() {
    cat <<'EOF'
Usage: install.sh {status|apply|rollback}

Installs or removes the NBA Live 07 native controller-profile fallback.
The game must be closed. Existing files are preserved before replacement.
EOF
}

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
action=$1
case $action in status|apply|rollback) ;; *) usage >&2; exit 2 ;; esac

if pgrep -x 'nbalive07.exe' >/dev/null; then
    echo 'Close NBA Live 07 before changing controller plugins.' >&2
    exit 1
fi

bottle=$("$repo_dir/bottles-game.sh" path nba-live-07)
game="$bottle/drive_c/Program Files (x86)/EA SPORTS/NBA LIVE 07"
plugins="$game/plugins"
target="$plugins/NBAControllerProfileFallback.asi"
backup="$plugins/NBAControllerProfileFallback.asi.pre-game-compat"

[[ -f $game/nbalive07.exe ]] || { echo 'NBA Live 07 executable was not found.' >&2; exit 1; }
actual_exe=$(sha256sum "$game/nbalive07.exe" | awk '{print $1}')
[[ $actual_exe == "$expected_exe" ]] || {
    echo 'Unsupported NBA Live 07 executable; refusing an address-specific patch.' >&2
    echo "Expected: $expected_exe" >&2
    echo "Found:    $actual_exe" >&2
    exit 1
}

case $action in
    status)
        if [[ -f $target ]]; then
            printf 'Installed: %s\n' "$target"
            sha256sum "$target"
        else
            echo 'Controller fallback is not installed.'
        fi
        ;;
    apply)
        [[ -f $artifact ]] || { echo "Compiled plugin is missing: $artifact" >&2; exit 1; }
        mkdir -p "$plugins"
        if [[ -e $target ]] && cmp -s "$artifact" "$target"; then
            echo 'NBA Live 07 controller fallback is already current.'
            sha256sum "$target"
            exit 0
        fi
        if [[ -e $target && ! -e $backup ]]; then
            mv "$target" "$backup"
        elif [[ -e $target && -e $backup ]]; then
            current_hash=$(sha256sum "$target" | awk '{print $1}')
            previous="$plugins/NBAControllerProfileFallback.asi.previous-${current_hash:0:12}"
            if [[ -e $previous ]] && ! cmp -s "$target" "$previous"; then
                echo "A different preserved update already exists: $previous" >&2
                exit 1
            fi
            mv "$target" "$previous"
        fi
        install -m 0644 "$artifact" "$target"
        echo 'Installed NBA Live 07 controller fallback.'
        sha256sum "$target"
        ;;
    rollback)
        if [[ -e $backup ]]; then
            if [[ -e $target ]]; then
                current_hash=$(sha256sum "$target" | awk '{print $1}')
                mv "$target" "$plugins/NBAControllerProfileFallback.asi.disabled-${current_hash:0:12}"
            fi
            mv "$backup" "$target"
            echo 'Restored the plugin that existed before game-compat installation.'
        elif [[ -e $target ]]; then
            mv "$target" "$plugins/NBAControllerProfileFallback.asi.game-compat-disabled"
            echo 'Disabled the game-compat controller fallback.'
        else
            echo 'Controller fallback is already absent.'
        fi
        ;;
esac
