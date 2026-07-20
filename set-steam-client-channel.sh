#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$root/lib/steam-paths.sh"

usage() {
    echo "Usage: $0 {status|stable|beta CHANNEL}"
}

steam_root=$(resolve_steam_root)
beta_file="$steam_root/package/beta"
backup_dir="$steam_root/package/game-compat-channel-backups"
action=${1:-}

current_channel() {
    if [[ -s $beta_file ]]; then
        printf 'beta:%s\n' "$(<"$beta_file")"
    else
        echo stable
    fi
}

[[ $action == status ]] && { current_channel; exit 0; }
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Refusing to change the client channel while Steam is running.' >&2
    exit 1
fi

mkdir -p "$backup_dir"
stamp=$(date +%Y%m%d-%H%M%S)
if [[ -e $beta_file ]]; then
    cp -a -- "$beta_file" "$backup_dir/beta.$stamp"
fi

case $action in
    stable)
        # Steam's own launcher treats an absent package/beta file as stable.
        if [[ -e $beta_file ]]; then
            mv -- "$beta_file" "$backup_dir/beta.removed.$stamp"
        fi
        [[ $(current_channel) == stable ]]
        ;;
    beta)
        [[ $# -eq 2 && $2 =~ ^[a-zA-Z0-9_-]+$ ]] || { usage >&2; exit 2; }
        printf '%s' "$2" > "$beta_file"
        [[ $(current_channel) == "beta:$2" ]]
        ;;
    *) usage >&2; exit 2 ;;
esac

printf 'Steam client channel: %s\n' "$(current_channel)"
echo "Backups: $backup_dir"
