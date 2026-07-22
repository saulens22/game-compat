#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
artwork_dir="$case_dir/configs/pokemon-scarlet-steam-artwork"
source_url='https://img-eshop.cdn.nintendo.net/i/7fcfb141b039b01209c625dffc94ab64192e92c11319566a7fa9c65d616e4708.jpg?w=1000'
source_sha256='6447eb1434c5afbae9b68275256b532837bd93351896b6f7761c1e86dc4749a1'

command -v magick >/dev/null || { echo 'ImageMagick is required for Steam artwork.' >&2; exit 1; }
mkdir -p "$artwork_dir"
source_image="$artwork_dir/source.jpg"
if [[ ! -f $source_image ]] || ! echo "$source_sha256  $source_image" | sha256sum --check --status; then
    curl --fail --location --output "$source_image" "$source_url"
fi
echo "$source_sha256  $source_image" | sha256sum --check --status

magick "$source_image" -resize '920x430^' -gravity center -extent 920x430 "$artwork_dir/grid.png"
magick "$source_image" -resize '600x900^' -gravity east -extent 600x900 "$artwork_dir/portrait.png"
magick "$source_image" -resize '1920x620^' -gravity center -extent 1920x620 "$artwork_dir/hero.png"
magick "$source_image" -resize '512x512^' -gravity east -extent 512x512 "$artwork_dir/icon.png"
magick -size 1000x300 xc:none -fill white -stroke '#4b0909' -strokewidth 5 \
    -gravity center -pointsize 86 -font DejaVu-Sans-Bold \
    -annotate +0+0 'POKÉMON SCARLET' "$artwork_dir/logo.png"

exec "$repo_dir/run-python-tool.sh" add-steam-shortcut.py \
    'Pokémon Scarlet' "$case_dir/launch-pokemon-scarlet.sh" --artwork-dir "$artwork_dir" "$@"
