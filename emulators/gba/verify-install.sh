#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../lib/load-env.sh
source "$case_dir/../../lib/load-env.sh"
root=$EMULATION_ROOT
rom=${RADICAL_RED_ROM:-$root/roms/gba/Pokemon - Radical Red 4.1.gba}
expected=679d112cdfe699c2793d82c7e7999ac9dfca9e222ad5a85d4f8f1e457cd0283f
[[ -s $root/cores/mgba_libretro.so ]] || { echo 'Managed mGBA core is missing.' >&2; exit 1; }
[[ -s $rom ]] || { echo "Patched ROM is missing: $rom" >&2; exit 1; }
actual=$(sha256sum "$rom" | awk '{print $1}')
[[ $actual == "$expected" ]] || { echo "Unexpected patched ROM hash: $actual" >&2; exit 1; }
echo 'Pokemon Radical Red 4.1 and the managed mGBA core are verified.'
