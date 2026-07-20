#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path kelyje-2)
game="$bottle/drive_c/Games/Kelyje2"
backup="$case_dir/configs/d2gi-backup"

pgrep -f '[R]igNRoll.exe' >/dev/null && { echo 'Close Kelyje 2 before rollback.' >&2; exit 1; }
echo 'This removes the installed D2GI files from this game and restores any saved predecessors.'
if [[ ${1:-} != --yes ]]; then read -r -p 'Continue? [y/N] ' answer; [[ $answer == [yY] ]] || exit 0; fi
for name in ddraw.dll d2gi.ini D2GI-LICENSE.txt; do
    [[ -f $game/$name ]] && unlink "$game/$name"
    [[ -f $backup/$name ]] && cp -a "$backup/$name" "$game/$name"
done
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b kelyje-2 --env-var 'WINEDLLOVERRIDES=ir50_32=n,b'
echo 'D2GI rollback complete.'
