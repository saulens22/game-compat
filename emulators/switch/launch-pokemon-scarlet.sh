#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec "$case_dir/launch-ryujinx-game.sh" 'Pokemon Scarlet' 'Pokemon Scarlet*.nsp'
