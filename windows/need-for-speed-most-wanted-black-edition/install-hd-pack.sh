#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: install-hd-pack.sh X360_EASY.zip HD_REFLECTIONS.zip

Installs the verified Xbox 360 Stuff Pack 4.1 Easy payload and NFS HD
Reflections into the existing nfsmw-black-edition bottle. The game itself must
already be installed. This script never accepts or copies game installation
media and never touches saves.
EOF
}

[[ $# -eq 2 ]] || { usage >&2; exit 2; }
stuff_archive=$(realpath -e -- "$1")
reflections_archive=$(realpath -e -- "$2")
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path nfsmw-black-edition)
game="$bottle/drive_c/Program Files/Mr DJ/Need For Speed Most Wanted Black Edition"
[[ -f $game/speed.exe ]] || { echo "Game is not installed: $game" >&2; exit 1; }
command -v unzip >/dev/null || { echo 'unzip is required.' >&2; exit 1; }
if pgrep -x speed.exe >/dev/null; then
    echo 'Close Need for Speed: Most Wanted before installing the HD pack.' >&2
    exit 1
fi

tmp=$(mktemp -d)
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT
unzip -q "$stuff_archive" -d "$tmp/stuff"
unzip -q "$reflections_archive" -d "$tmp/reflections"
stuff=$(find "$tmp/stuff" -type d -path '*/Easy Installation/Files' -print -quit)
reflections=$(find "$tmp/reflections" -type d -name NFSMWHDReflections -print -quit)
[[ -n $stuff && -n $reflections ]] || {
    echo 'The selected archives do not contain the expected Easy Installation and NFSMWHDReflections folders.' >&2
    exit 1
}

(cd "$stuff" && sha256sum -c "$case_dir/x360-stuff-v4.1.sha256")
(cd "$reflections" && sha256sum -c "$case_dir/nfsmw-hd-reflections-2025-11-15.sha256")

cp -a -- "$stuff/." "$game/"
cp -a -- "$reflections/." "$game/"

widescreen="$game/scripts/NFSMostWanted.WidescreenFix.ini"
hd_reflections="$game/scripts/NFSMWHDReflections.ini"
sed -i -E \
    -e 's/^(FixHUD[[:space:]]*=[[:space:]]*)[0-9]+/\10/' \
    -e 's/^(Scaling[[:space:]]*=[[:space:]]*)[0-9]+/\10/' \
    -e 's/^(FMVWidescreenMode[[:space:]]*=[[:space:]]*)[0-9]+/\10/' \
    -e 's/^(WriteSettingsToFile[[:space:]]*=[[:space:]]*)[0-9]+/\10/' \
    -e 's/^(ImproveShadowLOD[[:space:]]*=[[:space:]]*)[0-9]+/\11/' \
    -e 's/^(ConsoleGamma[[:space:]]*=[[:space:]]*)[0-9]+/\11/' \
    "$widescreen"
sed -i -E \
    -e 's/^(CubemapBrightnessFix[[:space:]]*=[[:space:]]*)[0-9]+/\10/' \
    -e 's/^(RestoreWaterReflections[[:space:]]*=[[:space:]]*)[0-9]+/\11/' \
    "$hd_reflections"

echo 'HD pack installed.'
echo 'Launch normally through Bottles or the existing optional Steam shortcut.'
