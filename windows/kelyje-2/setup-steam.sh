#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
artwork_dir="$case_dir/configs/steam-artwork"
base='https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/4487840'

command -v magick >/dev/null || { echo 'ImageMagick is required for Steam artwork.' >&2; exit 1; }
mkdir -p "$artwork_dir/sources"
download() {
    local name=$1 url=$2 expected=$3 target
    target="$artwork_dir/sources/$name"
    if [[ ! -f $target ]] || ! echo "$expected  $target" | sha256sum --check --status; then
        curl --fail --location --output "$target" "$url"
    fi
    echo "$expected  $target" | sha256sum --check --status || {
        echo "Artwork checksum mismatch: $name" >&2; exit 1;
    }
}
download portrait.jpg "$base/db3430e062b8c6cb29b2e85d292cc0fbf00e08bf/library_capsule.jpg" d3e2a1e526e2d43a3fbbdf33dccfc4efed6932ee208668dbaef937510be48ff3
download hero.jpg "$base/f17cc1785f6eda8160d1b709cc66e3342f683149/library_hero.jpg" d6d847e87fc439f91393f3072493b0b5aef2d0cdd6e99fdcf5d77903e2ee8063
download logo-source.png "$base/e52a66c3b68a88f6b4839a5084635dcb619c3d3a/logo.png" 802e31853ab7f422d9f23bad0b2fd3c802f7c2daf3828d7183435556d3d4881b
download grid.jpg "$base/6e0e28a791c095abb1e92df3cae7509768403b84/header.jpg" 348fe073d9165045904ada76794078725bfbc3a7a3bc1e0183da46574f944b69
download icon.jpg 'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4487840/e43cf7327ee56282a95a0a371a7c724d6be3d77d.jpg' ffd55d82721f8cb196b99b5b14b9d19e4a0dbc17057cf8b6f6ec4f0c88ecf368

magick "$artwork_dir/sources/portrait.jpg" -resize '600x900!' "$artwork_dir/portrait.png"
magick "$artwork_dir/sources/hero.jpg" -resize '1920x620!' "$artwork_dir/hero.png"
magick "$artwork_dir/sources/grid.jpg" -resize '920x430!' "$artwork_dir/grid.png"
magick "$artwork_dir/sources/logo-source.png" -resize '900x260' -gravity center -background none -extent 900x260 "$artwork_dir/logo.png"
magick "$artwork_dir/sources/icon.jpg" -filter Point -resize '512x512!' "$artwork_dir/icon.png"

exec "$repo_dir/add-bottles-steam-shortcut.sh" "$@" \
    --artwork-dir "$artwork_dir" \
    --dll-overrides 'ddraw=n,b;ir50_32=n,b' \
    kelyje-2 'Kelyje II' 'C:\Games\Kelyje2\RigNRoll.exe'
