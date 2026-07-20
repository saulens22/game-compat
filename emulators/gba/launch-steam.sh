#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../lib/load-env.sh
source "$case_dir/../../lib/load-env.sh"
root=$EMULATION_ROOT
rom=${RADICAL_RED_ROM:-$root/roms/gba/Pokemon - Radical Red 4.1.gba}
core=$root/cores/mgba_libretro.so
[[ -f $rom ]] || { echo "Patched ROM not found: $rom" >&2; exit 1; }
[[ -f $core ]] || { echo "mGBA core not found: $core" >&2; exit 1; }
log=$root/metadata/radical-red-retroarch.log
exec steam -applaunch 1118310 --verbose --log-file "$log" -L "$core" "$rom"
