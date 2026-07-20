#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

yes=0
[[ ${1:-} == --yes ]] && { yes=1; shift; }
[[ $# -eq 0 ]] || { echo 'Usage: rollback-receipt-save.sh [--yes]' >&2; exit 2; }
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null || pgrep -f '[M]urdered\.exe' >/dev/null; then
    echo 'Exit Murdered: Soul Suspect and Steam before rollback.' >&2
    echo 'This script never stops them automatically.' >&2
    exit 1
fi
pointer="$case_dir/runtime/latest-receipt-repair-backup"
[[ -f $pointer ]] || { echo 'No receipt-repair backup is recorded.' >&2; exit 1; }
backup_dir=$(<"$pointer")
for required in FATEGAME.SAV profile.bin remotecache.vdf; do
    [[ -f $backup_dir/$required ]] || { echo "Incomplete backup: missing $required" >&2; exit 1; }
done
((yes)) || {
    read -r -p 'Restore checkpoint, profile, and Cloud metadata from before the repair? [y/N] ' answer
    [[ $answer == [yY] ]] || { echo 'Cancelled.'; exit 1; }
}

steam_root=$(resolve_steam_root)
localconfig=$(steam_localconfig "$steam_root")
userdata_dir=$(cd -- "$(dirname -- "$localconfig")/.." && pwd)
cloud_dir="$userdata_dir/233290"
cp -a -- "$backup_dir/FATEGAME.SAV" "$cloud_dir/remote/SaveData/FateCheckpoint0/FATEGAME.SAV"
cp -a -- "$backup_dir/profile.bin" "$cloud_dir/remote/profile.bin"
cp -a -- "$backup_dir/remotecache.vdf" "$cloud_dir/remotecache.vdf"
sync "$cloud_dir/remote/SaveData/FateCheckpoint0/FATEGAME.SAV"
echo "Restored all save components from $backup_dir"
