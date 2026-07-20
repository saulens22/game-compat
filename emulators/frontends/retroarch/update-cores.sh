#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/load-env.sh
source "$case_dir/../../../lib/load-env.sh"
root=$EMULATION_ROOT
base=https://buildbot.libretro.com/nightly/linux/x86_64/latest
info_url=https://buildbot.libretro.com/assets/frontend/info.zip
cores=(mgba sameboy mesen snes9x bsnes mednafen_psx_hw panda3ds)
timestamp=$(date +%Y%m%d-%H%M%S)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

for command in curl unzip file sha256sum; do
    command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done
mkdir -p "$root"/{cores,core-info,backups/cores,metadata}

if compgen -G "$root/cores/*_libretro.so" >/dev/null; then
    mkdir -p "$root/backups/cores/$timestamp"
    cp -a -- "$root/cores/"*_libretro.so "$root/backups/cores/$timestamp/"
fi

printf 'core\tsha256\tsource\n' > "$tmp/core-builds.tsv"
for core in "${cores[@]}"; do
    archive="$tmp/${core}.zip"
    url="$base/${core}_libretro.so.zip"
    echo "Downloading $core from the official Libretro buildbot..."
    curl --fail --location --retry 3 --output "$archive" "$url"
    unzip -q -o "$archive" -d "$tmp/$core"
    library=$(find "$tmp/$core" -maxdepth 1 -type f -name '*_libretro.so' -print -quit)
    [[ -n $library ]] || { echo "No core library in $archive" >&2; exit 1; }
    file "$library" | grep -q 'ELF 64-bit' || { echo "Unexpected core format: $library" >&2; exit 1; }
    install -m 0755 "$library" "$root/cores/${core}_libretro.so.new"
    mv -f -- "$root/cores/${core}_libretro.so.new" "$root/cores/${core}_libretro.so"
    printf '%s\t%s\t%s\n' "$core" "$(sha256sum "$archive" | awk '{print $1}')" "$url" >> "$tmp/core-builds.tsv"
done

curl --fail --location --retry 3 --output "$tmp/info.zip" "$info_url"
unzip -q -o "$tmp/info.zip" -d "$tmp/info"
for core in "${cores[@]}"; do
    info=$(find "$tmp/info" -type f -name "${core}_libretro.info" -print -quit)
    [[ -n $info ]] || { echo "Missing core info for $core" >&2; exit 1; }
    install -m 0644 "$info" "$root/core-info/${core}_libretro.info"
done

mv -f -- "$tmp/core-builds.tsv" "$root/metadata/core-builds.tsv"
printf 'Updated %d cores. Recorded sources and hashes in %s\n' "${#cores[@]}" "$root/metadata/core-builds.tsv"
