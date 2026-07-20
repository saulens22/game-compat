#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
source "$repo_root/lib/steam-paths.sh"

unit='game-compat-steam-session.service'
steam_root=$(resolve_steam_root)

usage() {
    echo "Usage: $0 [--unit NAME.service] [--yes] {start|stop|restart|status}"
}

assume_yes=0
while [[ ${1:-} == --* ]]; do
    case $1 in
        --unit) unit=${2:?--unit requires a systemd user-unit name}; shift 2 ;;
        --yes) assume_yes=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done
action=${1:-}

confirm_stop() {
    echo 'WARNING: this action requests Steam to exit and may stop the managed Steam user service.'
    ((assume_yes)) && return 0
    if [[ ! -t 0 ]]; then
        echo 'Non-interactive stop/restart requires --yes.' >&2
        return 2
    fi
    read -r -p 'Continue and stop Steam? [y/N] ' answer
    [[ $answer == [yY] || $answer == [yY][eE][sS] ]]
}

client_ready() {
    pgrep -x steam >/dev/null && pgrep -x steamwebhelper >/dev/null
}

start_steam() {
    if client_ready; then
        echo 'Steam is already ready.'
        return
    fi

    systemctl --user import-environment \
        DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
        XAUTHORITY KDE_FULL_SESSION XDG_CURRENT_DESKTOP

    systemctl --user stop "$unit" 2>/dev/null || true
    systemd-run --user --unit="$unit" --collect \
        --property="WorkingDirectory=$steam_root" \
        --property='Restart=no' \
        /usr/bin/steam

    for _ in $(seq 1 90); do
        if client_ready; then
            echo 'Steam is ready (client and steamwebhelper verified).'
            return
        fi
        sleep 1
    done

    echo 'Steam did not become ready within 90 seconds.' >&2
    systemctl --user status "$unit" --no-pager >&2 || true
    journalctl --user -u "$unit" -n 100 --no-pager >&2 || true
    return 1
}

stop_steam() {
    if pgrep -x steam >/dev/null; then
        steam -shutdown >/dev/null 2>&1 || true
        for _ in $(seq 1 30); do
            pgrep -x steam >/dev/null || break
            sleep 1
        done
    fi
    if pgrep -x steam >/dev/null; then
        systemctl --user stop "$unit" 2>/dev/null || true
    fi
    if pgrep -x steam >/dev/null; then
        echo 'Steam processes remain after managed shutdown.' >&2
        return 1
    fi
    echo 'Steam is stopped.'
}

status_steam() {
    systemctl --user status "$unit" --no-pager || true
    pgrep -a -x steam || true
    pgrep -a -x steamwebhelper || true
    if client_ready; then
        echo 'Steam readiness: ready'
    else
        echo 'Steam readiness: not ready'
        return 1
    fi
}

case "$action" in
    start) start_steam ;;
    stop) confirm_stop && stop_steam ;;
    restart) confirm_stop && { stop_steam; start_steam; } ;;
    status) status_steam ;;
    *) usage; exit 2 ;;
esac
