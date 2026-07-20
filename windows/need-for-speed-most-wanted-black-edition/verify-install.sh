#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottle=$("$repo_dir/bottles-game.sh" path nfsmw-black-edition)
expected_exe=80774c2e5d619b4f120b48d4462896fd504c263399d203a238769cffde1d253c
fail=0

if rg -q '^Arch: win64$' "$bottle/bottle.yml"; then
    echo 'PASS: canonical NFSMW bottle uses the verified win64 architecture'
else
    echo 'FAIL: canonical NFSMW bottle is not win64' >&2
    fail=1
fi

mapfile -d '' executables < <(find "$bottle/drive_c" -type f -iname speed.exe -print0)
if [[ ${#executables[@]} -eq 1 ]] && [[ $(sha256sum "${executables[0]}" | awk '{print $1}') == "$expected_exe" ]]; then
    echo 'PASS: tested Black Edition 1.3 executable is installed'
    game=$(dirname "${executables[0]}")
else
    echo 'FAIL: expected exactly one tested Black Edition 1.3 executable' >&2
    exit 1
fi

for file in dinput8.dll scripts/NFSMostWanted.WidescreenFix.asi scripts/NFSMostWanted.WidescreenFix.ini scripts/NFSMostWanted.WidescreenFix.tpk; do
    if [[ -f $game/$file ]]; then echo "PASS: $file"; else echo "FAIL: missing $file" >&2; fail=1; fi
done
if find "$game/scripts" -maxdepth 1 -type f -iname 'NFSMW2005_widescreen_fix.asi' | grep -q .; then
    echo 'FAIL: incompatible legacy widescreen ASI is still active' >&2; fail=1
else
    echo 'PASS: no duplicate legacy widescreen ASI is active'
fi
if rg -q 'WINEDLLOVERRIDES: dinput8=n,b' "$bottle/bottle.yml" ||
   rg -q '^"dinput8"="native,builtin"$' "$bottle/user.reg"; then
    echo 'PASS: local dinput8 ASI loader is bottle-preferred'
else
    echo 'FAIL: dinput8 native override is missing' >&2; fail=1
fi
if rg -q '^Runner: ge-proton11-1$' "$bottle/bottle.yml" && rg -q '^    sync: ntsync$' "$bottle/bottle.yml"; then
    echo 'PASS: GE-Proton 11-1 and NT sync are configured'
else
    echo 'FAIL: expected GE-Proton 11-1 with NT sync' >&2; fail=1
fi
if rg -q '"\*d3dx9_26"="native"' "$bottle/user.reg"; then
    echo 'PASS: DirectX 9 dependency is native and runner-independent'
else
    echo 'FAIL: native d3dx9_26 override is missing' >&2; fail=1
fi
exit "$fail"
