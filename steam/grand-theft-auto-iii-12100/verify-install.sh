#!/usr/bin/env bash
set -euo pipefail
game_dir=${GTA3_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto 3"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
files=(d3d8.dll scripts/SilentPatchIII.asi scripts/SilentPatchIII.ini scripts/global.ini scripts/GTA3.WidescreenFix.asi scripts/GTA3.WidescreenFix.ini scripts/GInputIII.asi scripts/GInputIII.ini models/x360btns.txd models/ps3btns.txd models/sixaxis.txd)
for rel in "${files[@]}"; do [[ -s "$game_dir/$rel" ]] || { echo "Missing: $rel" >&2; exit 1; }; done
[[ ! -e "$game_dir/SilentPatchIII.asi" && ! -e "$game_dir/SilentPatchIII.ini" ]] || { echo 'Ignored root SilentPatch copy remains.' >&2; exit 1; }
grep -qx 'ResX = 0' "$game_dir/scripts/GTA3.WidescreenFix.ini"
grep -qx 'ResY = 0' "$game_dir/scripts/GTA3.WidescreenFix.ini"
grep -qx 'ControlsSet=5' "$game_dir/scripts/GInputIII.ini"
grep -qx 'PlayStationButtons=0' "$game_dir/scripts/GInputIII.ini"
grep -qx 'LeftStickSensitivity=75' "$game_dir/scripts/GInputIII.ini"
grep -qx 'RightStickSensitivity=75' "$game_dir/scripts/GInputIII.ini"
[[ -x "$case_dir/launch-with-intros.sh" ]]
[[ -s "$case_dir/runtime/intro-completion.mpg" ]]
[[ -s "$case_dir/mpv-intro-input.conf" ]]
[[ -x "$case_dir/runtime/controller-skip" ]]
[[ -s "$case_dir/controller-skip.c" ]]
grep -qx 'MBTN_LEFT quit' "$case_dir/mpv-intro-input.conf"
grep -q -- '--no-osc' "$case_dir/launch-with-intros.sh"
grep -q -- '--input-gamepad=yes' "$case_dir/launch-with-intros.sh"
grep -q -- '--input-ipc-server=' "$case_dir/launch-with-intros.sh"
grep -q 'command.*quit' "$case_dir/controller-skip.c"
grep -q 'controller-skip' "$case_dir/launch-with-intros.sh"
grep -q 'env -u LD_PRELOAD mpv' "$case_dir/launch-with-intros.sh"
grep -q 'env -u LD_PRELOAD "$controller_skip"' "$case_dir/launch-with-intros.sh"
for movie in Logo.mpg GTAtitles.mpg; do
  [[ -s "$game_dir/movies/$movie" ]]
  [[ ! -e "$game_dir/movies/$movie.gta3-intro-original" ]] || {
    echo "Unrestored intro backup remains: $movie" >&2; exit 1;
  }
done
echo 'PASS: GTA III fixes, native intro playback, display-independent resolution, and GTA IV-style controls are installed.'
