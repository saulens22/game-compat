#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
bottle_name=nfsmw-black-edition
program_name='Need for Speed Most Wanted Black Edition'
expected_exe=80774c2e5d619b4f120b48d4462896fd504c263399d203a238769cffde1d253c
archive_sha=e391ed97f8ebcbceced514a356ab2dc17f84fe500052026dd3448a6d5025aa92
archive_url='https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/nfsmw/NFSMostWanted.WidescreenFix.zip'

[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }
bottle=$($bottles path "$bottle_name")
[[ -f $bottle/bottle.yml ]] || { echo "Bottle does not exist: $bottle_name" >&2; exit 1; }

mapfile -d '' executables < <(find "$bottle/drive_c" -type f -iname speed.exe -print0)
[[ ${#executables[@]} -eq 1 ]] || {
    echo "Expected exactly one installed speed.exe, found ${#executables[@]}." >&2
    exit 1
}
exe=${executables[0]}
actual=$(sha256sum "$exe" | awk '{print $1}')
[[ $actual == "$expected_exe" ]] || {
    printf 'Installed executable is not the tested Black Edition 1.3 build.\nExpected: %s\nActual:   %s\n' "$expected_exe" "$actual" >&2
    exit 1
}
game=$(dirname "$exe")

cache="$case_dir/tool-downloads/widescreen-fix"
archive="$cache/NFSMostWanted.WidescreenFix.zip"
unpacked="$cache/unpacked"
backup="$case_dir/configs/pre-current-widescreen"
mkdir -p "$cache" "$unpacked" "$backup/scripts"
if [[ ! -f $archive ]]; then curl -fL --retry 3 -o "$archive" "$archive_url"; fi
actual=$(sha256sum "$archive" | awk '{print $1}')
[[ $actual == "$archive_sha" ]] || {
    printf 'Widescreen Fix checksum mismatch.\nExpected: %s\nActual:   %s\n' "$archive_sha" "$actual" >&2
    exit 1
}
bsdtar -xf "$archive" -C "$unpacked"

for relative in \
    dinput8.dll \
    scripts/NFSMW2005_widescreen_fix.asi \
    scripts/nfsmw_res.ini \
    scripts/NFSMostWanted.WidescreenFix.asi \
    scripts/NFSMostWanted.WidescreenFix.ini \
    scripts/NFSMostWanted.WidescreenFix.tpk; do
    if [[ -e $game/$relative && ! -e $backup/$relative ]]; then
        mkdir -p "$backup/$(dirname "$relative")"
        cp -a "$game/$relative" "$backup/$relative"
    fi
done

# Move the incompatible legacy generation out of the active scripts directory.
for relative in scripts/NFSMW2005_widescreen_fix.asi scripts/nfsmw_res.ini; do
    if [[ -e $game/$relative ]]; then mv "$game/$relative" "$backup/$relative"; fi
done
install -m 0644 "$unpacked/dinput8.dll" "$game/dinput8.dll"
install -m 0644 "$unpacked/scripts/NFSMostWanted.WidescreenFix.asi" "$game/scripts/NFSMostWanted.WidescreenFix.asi"
install -m 0644 "$unpacked/scripts/NFSMostWanted.WidescreenFix.ini" "$game/scripts/NFSMostWanted.WidescreenFix.ini"
install -m 0644 "$unpacked/scripts/NFSMostWanted.WidescreenFix.tpk" "$game/scripts/NFSMostWanted.WidescreenFix.tpk"

# Wine must prefer the local ASI loader. This is bottle-scoped.
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --env-var 'WINEDLLOVERRIDES=dinput8=n,b'

# A runner change must be completed before repairing prefix dependencies.
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --runner ge-proton11-1

"$repo_dir/bottles-winetricks.sh" "$bottle_name" d3dx9 d3dcompiler_47
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b "$bottle_name" --params 'sync:ntsync'

if ! "$bottles" programs "$bottle_name" | grep -Fxq -- "- $program_name"; then
    windows_exe=${exe#"$bottle/drive_c/"}
    windows_exe="C:\\${windows_exe//\//\\}"
    "$bottles" add "$bottle_name" "$program_name" "$windows_exe"
fi

"$case_dir/verify-install.sh"
echo "Fixes configured. Launch with: $case_dir/launch.sh"
