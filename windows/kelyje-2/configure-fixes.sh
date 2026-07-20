#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=kelyje-2
expected_exe=b7deb5fca7c4f2ab0eb8e02c3aae441eed13e3c4bb53797afd2df35f0721cc28

[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }

bottle=$($bottles path "$bottle_name")
[[ -f $bottle/bottle.yml ]] || {
    echo "Bottle $bottle_name does not exist; this command does not reinstall the game." >&2
    exit 1
}
exe="$bottle/drive_c/Games/Kelyje2/RigNRoll.exe"
[[ -f $exe ]] || { echo "Installed game executable not found: $exe" >&2; exit 1; }
actual=$(sha256sum "$exe" | awk '{print $1}')
[[ $actual == "$expected_exe" ]] || {
    printf 'Installed executable is not the verified Lithuanian 7.3 build.\nExpected: %s\nActual:   %s\n' "$expected_exe" "$actual" >&2
    exit 1
}

arch=$(sed -n 's/^Arch: //p' "$bottle/bottle.yml")
[[ $arch == win64 ]] || {
    echo "The supported Kelyje II setup requires a win64 bottle; found ${arch:-unknown}." >&2
    exit 1
}
codec="$bottle/drive_c/windows/syswow64/ir50_32.dll"
[[ -f $codec ]] || {
    echo 'Indeo 5 is not installed in this bottle. Run setup-bottle.sh to install the verified icodecs dependency.' >&2
    exit 1
}
rg -q '"vidc\.iv50"="(?:C:\\\\windows\\\\syswow64\\\\)?ir50_32\.dll"' "$bottle/system.reg" || {
    echo 'Indeo 5 file exists but its IV50 registry mapping is missing.' >&2
    exit 1
}

flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --env-var 'WINEDLLOVERRIDES=ir50_32=n,b'
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --win winxp

truck_ini="$bottle/drive_c/Games/Kelyje2/truck.ini"
cp -a "$truck_ini" "$case_dir/configs/truck-before-portable-install.ini"
sed -i $'s/^home=__noinst\r$/home=.\r/; s/^base=__noinst\r$/base=.\r/' "$truck_ini"
if ! rg -q $'^home=\.\r?$' "$truck_ini" || ! rg -q $'^base=\.\r?$' "$truck_ini"; then
    echo 'Could not configure the complete install as self-contained.' >&2; exit 1
fi

echo 'PASS: Indeo 5 native decoder preference configured.'
echo 'PASS: complete install configured for the documented self-contained no-CD path.'
echo "Launch with: $case_dir/launch.sh"
