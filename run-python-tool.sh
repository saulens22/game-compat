#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $# -ge 1 ]] || { echo "Usage: $0 SCRIPT.py [ARG...]" >&2; exit 2; }
script=$1; shift
[[ $script == /* ]] || script="$root/$script"
[[ -f $script ]] || { echo "Python tool not found: $script" >&2; exit 1; }

venv="$root/_work/python-venv"
requirements="$root/python-requirements.txt"
stamp="$venv/.requirements-sha256"
required_hash=$(sha256sum "$requirements" | awk '{print $1}')
if [[ ! -x $venv/bin/python ]]; then
    python3 -m venv "$venv"
fi
installed_hash=''
[[ -f $stamp ]] && IFS= read -r installed_hash <"$stamp"
if [[ $installed_hash != "$required_hash" ]]; then
    "$venv/bin/python" -m pip install --disable-pip-version-check -r "$requirements"
    printf '%s\n' "$required_hash" >"$stamp"
fi
exec "$venv/bin/python" "$script" "$@"
