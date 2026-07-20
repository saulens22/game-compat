#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "$0")" && pwd)
runtime="$case_dir/runtime/re3"
game=${GTA3_GAME_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto 3"}

[[ -x $runtime/re3 ]] || { echo "Build re3 first: $case_dir/build-re3.sh" >&2; exit 1; }
[[ -f $game/gta3.exe ]] || { echo "Owned GTA III assets not found: $game" >&2; exit 1; }

# Create an isolated merge tree. re3's supplied files win; every missing stock
# asset is a symlink to the installed Steam files. No Steam game file is
# copied, replaced, or made writable through this operation.
while IFS= read -r -d '' dir; do
    rel=${dir#"$game"/}
    [[ $dir == "$game" ]] && continue
    [[ -e $runtime/$rel ]] || mkdir -p -- "$runtime/$rel"
done < <(find "$game" -type d -print0)

while IFS= read -r -d '' source; do
    rel=${source#"$game"/}
    [[ -e $runtime/$rel || -L $runtime/$rel ]] && continue
    ln -s -- "$source" "$runtime/$rel"
done < <(find "$game" \( -type f -o -type l \) -print0)

printf 'Runtime: %s\nLocal assets: %s\n' "$runtime" "$game"
find "$runtime" -type l -print | wc -l | awk '{print "Linked local files: " $1}'
