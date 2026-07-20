#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$case_dir/../.." && pwd)
bottles="$repo_dir/bottles-game.sh"
[[ $# -eq 0 ]] || { echo "Usage: $0" >&2; exit 2; }

"$bottles" ensure kelyje-2 win64 gaming
bottle=$("$bottles" path kelyje-2)
game="$bottle/drive_c/Games/Kelyje2"
[[ -f $game/RigNRoll.exe ]] || {
    echo 'The bottle is ready, but Kelyje II is not installed.' >&2
    echo 'Copy the installation files into C:\Install\Kelyje2, install the complete game to C:\Games\Kelyje2, then rerun this command.' >&2
    exit 1
}
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b kelyje-2 --runner ge-proton11-1
flatpak run --command=bottles-cli com.usebottles.bottles edit \
    -b kelyje-2 --params 'sync:ntsync'

codec="$bottle/drive_c/windows/syswow64/ir50_32.dll"
if [[ ! -f $codec ]] || ! strings -el "$codec" | grep -Fq 'Video 5.11'; then
    # The Indeo installers contain 16-bit setup code. Wine bug 54670 was fixed
    # in Wine 10.16, but Winetricks still blocks icodecs on new WoW64. GE-Proton
    # 11 includes the fix, so --force bypasses that stale guard. Do not rerun it
    # once verified 5.11 is present because its first stage installs older 5.07.
    "$repo_dir/bottles-winetricks.sh" --force kelyje-2 icodecs
    cat <<'EOF'
The Winetricks silent path installed the older Indeo 5.07 decoder. Kelyje II
ships the same checksum-verified Ligos 5.11 installer used by Winetricks, but
5.11 must be completed interactively on new WoW64. Complete the installer that
opens now. Its optional DirectShow component may report an error; finish the
installer so the required VfW Indeo 5.11 decoder is installed.
EOF
    "$bottles" run-exe kelyje-2 'C:\Games\Kelyje2\iv5setup.exe'
fi
if [[ ! -f $codec ]] || ! strings -el "$codec" | grep -Fq 'Video 5.11'; then
    echo 'Ligos Indeo 5.11 was not installed; setup cannot continue.' >&2
    exit 1
fi
"$case_dir/configure-fixes.sh"
"$case_dir/install-d2gi.sh"
if ! "$bottles" programs kelyje-2 | grep -Fxq -- '- Kelyje 2'; then
    "$bottles" add kelyje-2 'Kelyje 2' 'C:\Games\Kelyje2\RigNRoll.exe'
fi
"$case_dir/verify-install.sh"
echo "Setup complete. Launch with: $case_dir/launch.sh"
