#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bottles-winetricks.sh [--force] BOTTLE VERB [VERB ...]

Install verified Winetricks dependencies into a Bottles-managed prefix using
that bottle's currently selected runner. Select the final runner first. The
game installer is never trusted to provide these dependencies.

--force is only for a game case that documents why upstream Winetricks rejects
the normal installation and verifies the resulting files and registry entries.
EOF
}

force=0
if [[ ${1:-} == --force ]]; then force=1; shift; fi
[[ $# -ge 2 ]] || { usage >&2; exit 2; }
bottle_name=$1
shift
[[ $bottle_name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || {
    echo "Invalid bottle name: $bottle_name" >&2; exit 2
}
for verb in "$@"; do
    [[ $verb =~ ^[a-zA-Z0-9_+-]+$ ]] || { echo "Invalid Winetricks verb: $verb" >&2; exit 2; }
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bottle=$("$script_dir/bottles-game.sh" path "$bottle_name")
[[ -f $bottle/bottle.yml ]] || { echo "Bottle does not exist: $bottle_name" >&2; exit 1; }
runner=$(awk -F': ' '$1 == "Runner" {print $2}' "$bottle/bottle.yml")
[[ -n $runner ]] || { echo 'Bottle has no selected runner.' >&2; exit 1; }
arch=$(awk -F': ' '$1 == "Arch" {print $2}' "$bottle/bottle.yml")
[[ $arch == win32 || $arch == win64 ]] || { echo "Unsupported bottle architecture: $arch" >&2; exit 1; }

for proc in /proc/[0-9]*; do
    [[ -r $proc/environ ]] || continue
    if (tr '\0' '\n' < "$proc/environ") 2>/dev/null | grep -Fqx "WINEPREFIX=$bottle"; then
        echo "Bottle is running (PID ${proc##*/}); stop it through Bottles before installing dependencies." >&2
        exit 1
    fi
done

flatpak info com.usebottles.bottles >/dev/null 2>&1 || {
    echo 'The officially supported Bottles Flatpak (com.usebottles.bottles) is required.' >&2
    exit 1
}
components="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/$runner"
wine=$(find "$components" -maxdepth 4 -type f -path '*/bin/wine' -perm -u+x -print -quit)
[[ -n $wine ]] || { echo "Runner files not found: $runner" >&2; exit 1; }
runner_bin=$(dirname "$wine")
quoted_verbs=$(printf ' %q' "$@")
force_arg=''
(( force )) && force_arg=' --force'
flatpak run --command=sh com.usebottles.bottles -c \
    "export WINEPREFIX='$bottle'; export WINEARCH='$arch'; export PATH='$runner_bin':\$PATH; export WINEDLLOVERRIDES='winemenubuilder='; winetricks$force_arg -q$quoted_verbs"

echo "Dependencies installed in $bottle_name: $*"
