#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
artwork_dir="$case_dir/configs/steam-artwork"
source_url='https://cdn2.steamgriddb.com/thumb/a86cc0b404ab003e0badb9ed96b55ace.png'
source_sha256='e5865f764924fb63b4a9fbcda9461f30bdaeeb32b0649138518b528cca93b62a'

command -v magick >/dev/null || {
    echo 'ImageMagick is required to prepare Steam artwork.' >&2
    exit 1
}
mkdir -p "$artwork_dir"
source_image="$artwork_dir/source.png"
if [[ ! -f $source_image ]] || ! echo "$source_sha256  $source_image" | sha256sum --check --status; then
    curl --fail --location --output "$source_image" "$source_url"
fi
echo "$source_sha256  $source_image" | sha256sum --check --status || {
    echo 'Steam artwork download failed its checksum.' >&2
    exit 1
}

# Steam uses several aspect ratios. Build a clean set from the selected cover:
# a fitted cover for portrait/icon views and a blurred-cover backdrop for wide
# library and hero views. These generated files stay local and are not committed.
magick "$source_image" -filter Lanczos -resize '600x900!' "$artwork_dir/portrait.png"
magick "$source_image" -filter Lanczos -resize '512x512^' -gravity center -extent 512x512 "$artwork_dir/icon.png"
magick "$source_image" -resize '920x430^' -gravity center -extent 920x430 -blur 0x18 \
    \( "$source_image" -resize '287x430' \) -gravity center -compose over -composite "$artwork_dir/grid.png"
magick "$source_image" -resize '1920x620^' -gravity center -extent 1920x620 -blur 0x24 \
    \( "$source_image" -resize '414x620' \) -gravity center -compose over -composite "$artwork_dir/hero.png"
magick -size 900x260 xc:none -fill white -stroke black -strokewidth 3 \
    -gravity center -pointsize 66 -font DejaVu-Sans-Bold \
    -annotate +0+0 'NEED FOR SPEED\nMOST WANTED' "$artwork_dir/logo.png"

exec "$repo_dir/add-bottles-steam-shortcut.sh" "$@" \
    --artwork-dir "$artwork_dir" \
    --prepare-script "$case_dir/prepare-steam-launch.sh" \
    --replace-name 'NFSMW Black Edition — Steam shared-prefix test' \
    nfsmw-black-edition 'Need for Speed: Most Wanted Black Edition' \
    'C:\Program Files\Mr DJ\Need For Speed Most Wanted Black Edition\speed.exe'
