#!/usr/bin/env bash
set -euo pipefail
game_dir=${GTASA_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto San Andreas"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$case_dir/../../lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
files=(vorbisFile.dll SilentPatchSA.asi SilentPatchSA.ini)
for rel in "${files[@]}"; do [[ -s "$game_dir/$rel" ]] || { echo "Missing: $rel" >&2; exit 1; }; done
[[ ! -e "$game_dir/scripts/GTASA.WidescreenFix.asi" ]] || { echo 'Incompatible GTASA.WidescreenFix.asi is installed.' >&2; exit 1; }
grep -Eq '^SkipIntroSplashes=0[[:space:]]*$' "$game_dir/SilentPatchSA.ini"
controller_count=0
while IFS= read -r -d '' controller; do
  controller_count=$((controller_count + 1))
  grep -q 'controller_xboxone_gamepad_joystick.vdf' "$controller"
  ! grep -q '870598734' "$controller"
done < <(steam_controller_configs "$steam_root")
((controller_count > 0)) || { echo 'No Xbox controller configuration found.' >&2; exit 1; }
echo 'PASS: SA NewSteam fix stack, full intro setting, and default Steam gamepad layout are installed.'
