#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/steam-paths.sh
source "$root/lib/steam-paths.sh"

[[ $# -ge 1 ]] || { echo "Usage: $0 APP_ID [APP_ID ...]" >&2; exit 2; }
for app_id in "$@"; do
    [[ $app_id =~ ^[0-9]+$ ]] || { echo "Invalid App ID: $app_id" >&2; exit 2; }
done
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Refusing to edit compatibility mappings while Steam is running.' >&2
    exit 1
fi

steam_root=$(resolve_steam_root)
file="$steam_root/config/config.vdf"
backup_dir="$(dirname "$file")/game-compat-backups"
mkdir -p "$backup_dir"
backup="$backup_dir/config.vdf.$(date +%Y%m%d-%H%M%S-%N)"
cp -a -- "$file" "$backup"

for app_id in "$@"; do
    APP_ID=$app_id perl -i -ne '
        BEGIN { $mapping=0; $mapping_wait=0; $mapping_depth=0; $skip=0; $skip_wait=0; $skip_depth=0 }
        if (!$mapping && !$mapping_wait && /^\s*"CompatToolMapping"\s*$/) {
            $mapping_wait=1; print; next;
        }
        if ($mapping_wait) {
            print;
            if (/\{/) { $mapping=1; $mapping_wait=0; $mapping_depth=1 }
            next;
        }
        if ($mapping) {
            $opens = tr/{/{/; $closes = tr/}/}/;
            if (!$skip && /^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $skip_wait=1; next }
            if ($skip_wait) {
                if ($opens) { $skip=1; $skip_wait=0; $skip_depth=$opens-$closes }
                next;
            }
            if ($skip) {
                $skip_depth += $opens-$closes;
                $skip=0 if $skip_depth == 0;
                next;
            }
            print;
            $mapping_depth += $opens-$closes;
            $mapping=0 if $mapping_depth == 0;
            next;
        }
        print;
    ' "$file"
done

for app_id in "$@"; do
    if APP_ID=$app_id perl -ne '
        if (!$mapping && /^\s*"CompatToolMapping"\s*$/) { $mapping_wait=1; next }
        if ($mapping_wait && /\{/) { $mapping=1; $mapping_wait=0; $depth=1; next }
        if ($mapping) {
            if (/^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $found=1; last }
            $opens=tr/{/{/; $closes=tr/}/}/; $depth += $opens-$closes;
            $mapping=0 if $depth == 0;
        }
        END { exit($found ? 0 : 1) }
    ' "$file"; then
        cp -a -- "$backup" "$file"
        echo "Failed to remove mapping $app_id; backup restored." >&2
        exit 1
    fi
done
echo "Removed obsolete compatibility mapping(s): $*"
echo "Backup: $backup"
