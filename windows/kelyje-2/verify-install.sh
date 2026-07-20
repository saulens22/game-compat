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
if rg -q '^Arch: win64$' "$bottle/bottle.yml" && rg -q '^Runner: ge-proton11-1$' "$bottle/bottle.yml"; then
    echo 'PASS: canonical bottle uses win64 and GE-Proton 11-1'
else
    echo 'FAIL: canonical bottle is not win64 with GE-Proton 11-1' >&2; fail=1
fi
check_file "$bottle/drive_c/Games/Kelyje2/RigNRoll.exe" 'Lithuanian game executable exists'
check_file "$bottle/drive_c/windows/syswow64/ir50_32.dll" '32-bit Indeo 5 decoder exists in the win64 prefix'
if strings -el "$bottle/drive_c/windows/syswow64/ir50_32.dll" | grep -Fq 'Video 5.11'; then
    echo 'PASS: required Ligos Indeo 5.11 VfW decoder is installed'
else
    echo 'FAIL: installed Indeo decoder is not Ligos 5.11' >&2; fail=1
fi
check_file "$bottle/drive_c/Games/Kelyje2/ddraw.dll" 'D2GI DirectDraw wrapper exists'
check_file "$bottle/drive_c/Games/Kelyje2/d2gi.ini" 'D2GI dynamic display configuration exists'
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
if rg -q '"vidc\.iv50"="(?:C:\\\\windows\\\\syswow64\\\\)?ir50_32\.dll"' "$bottle/system.reg"; then
    echo 'PASS: IV50 is registered to the Indeo decoder'
else
    echo 'FAIL: IV50 registry mapping is missing' >&2; fail=1
fi
exit "$fail"
