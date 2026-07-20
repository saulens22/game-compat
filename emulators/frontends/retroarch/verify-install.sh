#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../../.." && pwd)
# shellcheck source=../../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
library=$EMULATION_ROOT
systems_file=$(cd -- "$case_dir/../.." && pwd)/systems.txt
cores=(mgba sameboy mesen snes9x bsnes mednafen_psx_hw panda3ds)
failed=0
config=${RETROARCH_CONFIG:-$(steam_app_install_dir "$(resolve_steam_root)" 1118310)/retroarch.cfg}
for directory in bios cores core-info metadata playlists saves states screenshots configs roms; do
    [[ -d $library/$directory ]] || { echo "Missing directory: $library/$directory" >&2; failed=1; }
done
while read -r system _; do
    [[ -n $system && $system != \#* ]] || continue
    [[ -d $library/roms/$system ]] || { echo "Missing system directory: $library/roms/$system" >&2; failed=1; }
done < "$systems_file"
[[ $(sed -n 's/^input_remapping_directory = "\(.*\)"/\1/p' "$config") == "$library/configs/remaps" ]] || {
    echo 'RetroArch input remapping directory is not configured for the external library.' >&2; failed=1;
}
declare -A expected=(
    [audio_fastforward_mute]=false
    [audio_fastforward_speedup]=false
    [fastforward_ratio]=4.000000
    [fastforward_ratio_throttle_enable]=true
    [input_hold_fast_forward_axis]=+5
    [input_menu_toggle_btn]=6
    [input_player1_analog_dpad_mode]=1
    [input_rewind_axis]=+4
)
for key in "${!expected[@]}"; do
    actual=$(sed -n "s/^$key = \"\(.*\)\"/\1/p" "$config")
    [[ $actual == "${expected[$key]}" ]] || {
        echo "Unexpected $key: ${actual:-missing} (expected ${expected[$key]})" >&2
        failed=1
    }
done
remap=$library/configs/remaps/mGBA/mGBA.rmp
for mapping in \
    'input_player1_analog_dpad_mode = "1"' \
    'input_player1_btn_a = "0"' \
    'input_player1_btn_b = "8"' \
    'input_player1_btn_l2 = "-1"' \
    'input_player1_btn_r2 = "-1"' \
    'input_player1_btn_select = "-1"' \
    'input_player1_btn_start = "-1"' \
    'input_player1_btn_x = "3"' \
    'input_player1_btn_y = "2"'; do
    grep -Fqx "$mapping" "$remap" || { echo "Missing mGBA remap: $mapping" >&2; failed=1; }
done
for core in "${cores[@]}"; do
    [[ -s $library/cores/${core}_libretro.so ]] || { echo "Missing core: $core" >&2; failed=1; }
    [[ -s $library/core-info/${core}_libretro.info ]] || { echo "Missing core info: $core" >&2; failed=1; }
done
[[ -s $library/metadata/core-builds.tsv ]] || { echo 'Missing core source/hash ledger.' >&2; failed=1; }
(( failed == 0 )) || exit 1
echo "RetroArch external library and ${#cores[@]} managed cores verified."
