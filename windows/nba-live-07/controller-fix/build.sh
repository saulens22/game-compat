#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cxx=${CXX:-i686-w64-mingw32-g++}
command -v "$cxx" >/dev/null || {
    echo 'A 32-bit MinGW-w64 C++ compiler is required.' >&2
    echo 'Set CXX if i686-w64-mingw32-g++ has a different name.' >&2
    exit 1
}

# Fixed neutral linker metadata keeps the checked-in PE reproducible. The
# module is relocatable, so the preferred image base does not constrain ASLR.
SOURCE_DATE_EPOCH=1 "$cxx" \
    -std=c++17 -O2 -Wall -Wextra -Werror \
    -shared -static-libgcc -static-libstdc++ \
    -Wl,--subsystem,windows -Wl,--image-base,0x65000000 \
    -o "$root/NBAControllerProfileFallback-v2.asi" \
    "$root/nba_controller_profile_fallback.cpp"

sha256sum "$root/NBAControllerProfileFallback-v2.asi"
