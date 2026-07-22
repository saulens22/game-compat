#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=nba-live-07
program='NBA Live 07'
game_exe=nbalive07.exe
assume_yes=0
cleanup=1

usage() {
    cat <<'EOF'
Usage: launch.sh [--yes] [--no-cleanup]

Launch NBA Live 07 through its Bottles program. By default, after the game
exits, remaining Wine processes in this bottle are stopped so Bottles and a
Steam shortcut do not remain stuck in the Running state.

  --yes         accept the bottle-cleanup warning without prompting
  --no-cleanup  leave Wine/Bottles helper processes running after game exit
EOF
}

while (($#)); do
    case $1 in
        --yes) assume_yes=1 ;;
        --no-cleanup) cleanup=0 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

if ((cleanup)); then
    echo "WARNING: after the game exits, this launcher stops remaining Wine processes in bottle $bottle." >&2
    echo 'Unsaved work in this same bottle could be lost. Steam and other bottles are not stopped.' >&2
    if ((!assume_yes)); then
        read -r -p 'Launch with automatic bottle cleanup? [y/N] ' answer
        [[ $answer == [yY] ]] || exit 0
    fi
fi

"$case_dir/prepare-launch.sh"
bottle_path=$("$repo_dir/bottles-game.sh" path "$bottle")

game_pids() {
    local proc env cmd
    for proc in /proc/[0-9]*; do
        [[ -r $proc/environ && -r $proc/cmdline ]] || continue
        env=$( (tr '\0' '\n' <"$proc/environ") 2>/dev/null || true)
        grep -Fqx "WINEPREFIX=$bottle_path" <<<"$env" || continue
        cmd=$(tr '\0' ' ' <"$proc/cmdline" 2>/dev/null || true)
        [[ ${cmd,,} == *"$game_exe"* ]] && printf '%s\n' "${proc##*/}"
    done
}

"$repo_dir/bottles-game.sh" run "$bottle" "$program" &
launcher_pid=$!

# Bottles may keep explorer.exe /desktop alive after this old game closes.
# Follow the real game process instead of waiting forever for that helper.
seen=0
for _ in {1..600}; do
    mapfile -t running < <(game_pids)
    if ((${#running[@]})); then seen=1; break; fi
    kill -0 "$launcher_pid" 2>/dev/null || break
    sleep 0.2
done

if ((!seen)); then
    wait "$launcher_pid"
    exit $?
fi

while :; do
    mapfile -t running < <(game_pids)
    ((${#running[@]})) || break
    sleep 0.5
done

if ((cleanup)); then
    "$repo_dir/bottles-game.sh" stop "$bottle" --yes || true
fi

for _ in {1..20}; do
    kill -0 "$launcher_pid" 2>/dev/null || { wait "$launcher_pid" 2>/dev/null || true; exit 0; }
    sleep 0.1
done

if ((cleanup)); then
    echo 'Bottles launcher did not exit after Wine cleanup; sending SIGTERM.' >&2
    kill -TERM "$launcher_pid" 2>/dev/null || true
    for _ in {1..20}; do
        kill -0 "$launcher_pid" 2>/dev/null || { wait "$launcher_pid" 2>/dev/null || true; exit 0; }
        sleep 0.1
    done
    echo 'Bottles launcher still did not exit; using SIGKILL fallback.' >&2
    kill -KILL "$launcher_pid" 2>/dev/null || true
fi
wait "$launcher_pid" 2>/dev/null || true
