#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "$0")" && pwd)
source_dir="$case_dir/source/re3"
build_dir="$source_dir/build-linux"
runtime="$case_dir/runtime/re3"
repo='https://git.shihaam.dev/archivemirrors/re3.git'
commit='310dd8637147c4db643107b69d603902abc78141'

if [[ ! -d $source_dir/.git ]]; then
    mkdir -p "$(dirname "$source_dir")"
    git clone --recursive "$repo" "$source_dir"
fi

git -C "$source_dir" fetch --all --tags
git -C "$source_dir" checkout --detach "$commit"
git -C "$source_dir" submodule update --init --recursive

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBRW_PLATFORM=GL3 \
    -DLIBRW_GL3_GFXLIB=GLFW \
    -DRE3_AUDIO=OAL \
    -DRE3_INSTALL=ON \
    -DCMAKE_INSTALL_PREFIX="$runtime"
cmake --build "$build_dir" --parallel "$(nproc)"
cmake --install "$build_dir"

sha256sum "$runtime/re3"
