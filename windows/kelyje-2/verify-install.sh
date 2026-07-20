#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path kelyje-2)
fail=0
check_file() {
    if [[ -f $1 ]]; then echo "PASS: $2"; else echo "FAIL: $2 ($1)" >&2; fail=1; fi
}

check_file "$bottle/bottle.yml" 'dedicated Bottles bottle exists'
check_file "$bottle/drive_c/Games/Kelyje2/RigNRoll.exe" 'Lithuanian game executable exists'
check_file "$bottle/drive_c/windows/system32/ir50_32.dll" 'Indeo 5 decoder exists'
check_file "$bottle/drive_c/Games/Kelyje2/ddraw.dll" 'D2GI DirectDraw wrapper exists'
check_file "$bottle/drive_c/Games/Kelyje2/d2gi.ini" 'D2GI dynamic display configuration exists'
check_file "$bottle/drive_c/Media/Kelyje2.media" 'verified source file is stored inside the bottle'
if [[ -f $bottle/drive_c/Media/Kelyje2.media ]] &&
   [[ $(sha256sum "$bottle/drive_c/Media/Kelyje2.media" | awk '{print $1}') == 9b80360c004bb5eb4aab3de6aa27e76b060867a796895de5bc8ce5ec8957b5b1 ]]; then
    echo 'PASS: bottle-local source checksum matches'
else
    echo 'FAIL: bottle-local source checksum mismatch' >&2; fail=1
fi
if rg -q $'^home=\.\r?$' "$bottle/drive_c/Games/Kelyje2/truck.ini" &&
   rg -q $'^base=\.\r?$' "$bottle/drive_c/Games/Kelyje2/truck.ini" &&
   rg -q $'^source=\.\r?$' "$bottle/drive_c/Games/Kelyje2/truck.ini"; then
    echo 'PASS: complete 7.3 install uses its documented self-contained no-CD paths'
else
    echo 'FAIL: self-contained no-CD paths are not configured' >&2; fail=1
fi
if rg -q '"CurrentVersion"="5\.1"' "$bottle/system.reg" &&
   rg -q '"ProductName"="Microsoft Windows XP"' "$bottle/system.reg"; then
    echo 'PASS: Wine compatibility mode is Windows XP'
else
    echo 'FAIL: Wine compatibility mode is not Windows XP' >&2; fail=1
fi
if rg -q 'WINEDLLOVERRIDES: ir50_32=n,b;ddraw=n,b' "$bottle/bottle.yml"; then
    echo 'PASS: native Indeo decoder and D2GI preferences are active'
else
    echo 'FAIL: native Indeo decoder preference is missing' >&2; fail=1
fi
if rg -q '"vidc\.iv50"="ir50_32\.dll"' "$bottle/system.reg"; then
    echo 'PASS: IV50 is registered to the Indeo decoder'
else
    echo 'FAIL: IV50 registry mapping is missing' >&2; fail=1
fi
exit "$fail"
