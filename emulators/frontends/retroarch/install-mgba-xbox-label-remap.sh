#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/load-env.sh
source "$case_dir/../../../lib/load-env.sh"
root=$EMULATION_ROOT
destination=$root/configs/remaps/mGBA/mGBA.rmp
mkdir -p "$(dirname "$destination")" "$root/backups/remaps"
if [[ -f $destination ]]; then
    cp -a -- "$destination" "$root/backups/remaps/mGBA.rmp.$(date +%Y%m%d-%H%M%S)"
fi
cat > "$destination" <<'EOF'
input_player1_analog_dpad_mode = "1"
input_player1_btn_a = "0"
input_player1_btn_b = "8"
input_player1_btn_l2 = "-1"
input_player1_btn_r2 = "-1"
input_player1_btn_select = "-1"
input_player1_btn_start = "-1"
input_player1_btn_y = "2"
input_player1_btn_x = "3"
EOF
echo 'Installed mGBA-only Xbox label remap:'
echo '  Xbox A (south) -> GBA A'
echo '  Xbox B (east)  -> GBA B'
echo '  Xbox X (west)  -> GBA Select'
echo '  Xbox Y (north) -> GBA Start'
echo "File: $destination"
