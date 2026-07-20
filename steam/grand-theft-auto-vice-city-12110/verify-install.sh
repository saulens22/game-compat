#!/usr/bin/env bash
set -euo pipefail
game_dir=${GTAVC_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto Vice City"}
files=(d3d8.dll scripts/SilentPatchVC.asi scripts/SilentPatchVC.ini scripts/global.ini scripts/GTAVC.WidescreenFix.asi scripts/GTAVC.WidescreenFix.ini)
for rel in "${files[@]}"; do [[ -s "$game_dir/$rel" ]] || { echo "Missing: $rel" >&2; exit 1; }; done
[[ ! -e "$game_dir/SilentPatchVC.asi" && ! -e "$game_dir/SilentPatchVC.ini" ]] || { echo 'Ignored root SilentPatch copy remains.' >&2; exit 1; }
grep -Eq '^ResX[[:space:]]*=[[:space:]]*0[[:space:]]*$' "$game_dir/scripts/GTAVC.WidescreenFix.ini"
grep -Eq '^ResY[[:space:]]*=[[:space:]]*0[[:space:]]*$' "$game_dir/scripts/GTAVC.WidescreenFix.ini"
echo 'PASS: Vice City fix files and display-independent resolution settings are installed.'
