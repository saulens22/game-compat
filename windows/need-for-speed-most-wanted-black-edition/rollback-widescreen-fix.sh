#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
yes=0
[[ ${1:-} == --yes ]] && { yes=1; shift; }
[[ $# -eq 0 ]] || { echo "Usage: $0 [--yes]" >&2; exit 2; }

echo 'WARNING: this replaces the active widescreen files. Close the game first.' >&2
if (( ! yes )); then
    read -r -p 'Restore the backed-up bundled widescreen generation? [y/N] ' answer
    [[ $answer == [yY] ]] || exit 0
fi

bottle=$("$repo_dir/bottles-game.sh" path nfsmw-black-edition)
mapfile -d '' executables < <(find "$bottle/drive_c" -type f -iname speed.exe -print0)
[[ ${#executables[@]} -eq 1 ]] || { echo 'Installed game was not found uniquely.' >&2; exit 1; }
game=$(dirname "${executables[0]}")
backup="$case_dir/configs/pre-current-widescreen"
[[ -f $backup/dinput8.dll && -f $backup/scripts/NFSMW2005_widescreen_fix.asi ]] || {
    echo 'Rollback backup is incomplete.' >&2; exit 1
}
mkdir -p "$case_dir/configs/current-widescreen-disabled/scripts"
for relative in dinput8.dll scripts/NFSMostWanted.WidescreenFix.asi scripts/NFSMostWanted.WidescreenFix.ini scripts/NFSMostWanted.WidescreenFix.tpk; do
    if [[ -e $game/$relative ]]; then mv "$game/$relative" "$case_dir/configs/current-widescreen-disabled/$relative"; fi
done
cp -a "$backup/dinput8.dll" "$game/dinput8.dll"
cp -a "$backup/scripts/NFSMW2005_widescreen_fix.asi" "$game/scripts/"
[[ ! -f $backup/scripts/nfsmw_res.ini ]] || cp -a "$backup/scripts/nfsmw_res.ini" "$game/scripts/"
echo 'Bundled widescreen generation restored. Re-run configure-fixes.sh to return to the current fix.'
