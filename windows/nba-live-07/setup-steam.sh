#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
artwork_dir="$case_dir/configs/steam-artwork"
cover_url='https://upload.wikimedia.org/wikipedia/en/a/a6/NBAlive07.jpg'
cover_sha256='b375be1b8598e97144a02a1b6eed065e27c48b605d2f0f62ff51316b55818d0f'
logo_url='https://upload.wikimedia.org/wikipedia/commons/1/12/Nba-live-07-mono-logo.png'
logo_sha256='356612fbb82743398530882ff6ca56fd61facd5b8778e442b5d9086b247bf803'

command -v magick >/dev/null || {
    echo 'ImageMagick is required to prepare Steam artwork.' >&2
    exit 1
}
mkdir -p "$artwork_dir/sources"

download() {
    local target=$1 url=$2 expected=$3
    if [[ ! -f $target ]] || ! echo "$expected  $target" | sha256sum --check --status; then
        curl --fail --location --output "$target" "$url"
    fi
    echo "$expected  $target" | sha256sum --check --status || {
        echo "Artwork checksum mismatch: $target" >&2
        exit 1
    }
}

cover="$artwork_dir/sources/cover.jpg"
logo="$artwork_dir/sources/logo.png"
download "$cover" "$cover_url" "$cover_sha256"
download "$logo" "$logo_url" "$logo_sha256"

magick "$cover" -filter Lanczos -resize '600x900!' "$artwork_dir/portrait.png"
magick "$cover" -filter Lanczos -resize '512x512^' -gravity center -extent 512x512 \
    "$artwork_dir/icon.png"
magick "$cover" -resize '920x430^' -gravity center -extent 920x430 -blur 0x18 \
    \( "$cover" -resize '304x430' \) -gravity center -compose over -composite \
    "$artwork_dir/grid.png"
magick "$cover" -resize '1920x620^' -gravity center -extent 1920x620 -blur 0x24 \
    \( "$cover" -resize '438x620' \) -gravity center -compose over -composite \
    "$artwork_dir/hero.png"
magick "$logo" -resize '860x240' -gravity center -background none -extent 900x260 \
    "$artwork_dir/logo.png"

exec "$repo_dir/add-bottles-steam-shortcut.sh" "$@" \
    --artwork-dir "$artwork_dir" \
    --prepare-script "$case_dir/prepare-steam-launch.sh" \
    --dll-overrides 'd3d9=n,b;dinput=n,b' \
    --replace-name 'NBA Live 07' \
    nba-live-07 'NBA Live 07' \
    'C:\Program Files (x86)\EA SPORTS\NBA LIVE 07\nbalive07.exe'
