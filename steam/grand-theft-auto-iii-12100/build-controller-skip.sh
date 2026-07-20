#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
command -v gcc >/dev/null || {
  echo "gcc is missing. Run $case_dir/../../install-system-packages.sh gta3" >&2
  exit 1
}
mkdir -p "$case_dir/runtime"
gcc -std=c11 -O2 -Wall -Wextra -Werror \
  -o "$case_dir/runtime/controller-skip" "$case_dir/controller-skip.c"
echo "Built $case_dir/runtime/controller-skip"
