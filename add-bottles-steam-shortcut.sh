#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/steam-paths.sh
source "$root/lib/steam-paths.sh"

usage() {
    cat <<'EOF'
Usage: add-bottles-steam-shortcut.sh [OPTIONS] BOTTLE SHORTCUT_NAME WINDOWS_EXE

Options:
  --artwork-dir DIR      Steam artwork accepted by add-steam-shortcut.py
  --prepare-script FILE  host helper to run before Steam Proton starts the game
  --dll-overrides VALUE  Wine DLL overrides required by game-local fixes
  --env NAME=VALUE       add a launch environment variable; repeatable
  --replace-name NAME    remove an obsolete exact shortcut name; repeatable
  --yes                  allow add-steam-shortcut.py to close Steam
  --no-restart           leave Steam stopped afterward

Creates one direct Steam shortcut for a win64 Bottles prefix and pins it to
Proton-GE Latest. Steam Proton and Bottles then share one prefix. This is
convenient and restores Overlay, but is inherently brittle because both tools
may update that prefix. Snapshot the bottle before changing either runner.
EOF
}

artwork=''
prepare=''
dll_overrides=''
yes=0
restart=1
replace_names=()
launch_env=()
while [[ ${1:-} == --* ]]; do
    case $1 in
        --artwork-dir) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; artwork=$2; shift 2 ;;
        --prepare-script) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; prepare=$2; shift 2 ;;
        --dll-overrides) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; dll_overrides=$2; shift 2 ;;
        --env)
            [[ $# -ge 2 && $2 =~ ^[A-Za-z_][A-Za-z0-9_]*=[^$'\n']*$ ]] || {
                echo '--env requires NAME=VALUE without a newline.' >&2; exit 2;
            }
            launch_env+=("$2")
            shift 2
            ;;
        --replace-name) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; replace_names+=("$2"); shift 2 ;;
        --yes) yes=1; shift ;;
        --no-restart) restart=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
[[ $# -eq 3 ]] || { usage >&2; exit 2; }
bottle_name=$1
shortcut_name=$2
windows_exe=$3

bottle=$("$root/bottles-game.sh" path "$bottle_name")
[[ -f $bottle/bottle.yml ]] || { echo "Bottle does not exist: $bottle_name" >&2; exit 1; }
rg -q '^Arch: win64$' "$bottle/bottle.yml" || {
    echo 'Direct Steam Proton prefix sharing requires the game bottle to be win64.' >&2
    exit 1
}
[[ $windows_exe =~ ^[Cc]:\\ ]] || { echo "WINDOWS_EXE must begin with C:\\" >&2; exit 2; }
relative=${windows_exe:3}
relative=${relative//\\//}
target="$bottle/drive_c/$relative"
[[ -f $target ]] || { echo "Game executable is missing: $target" >&2; exit 1; }
# Steam validates a direct non-Steam target as a host executable before its
# compatibility tool runs. Wine itself does not require this bit, but Steam
# reports an invalid configuration without it.
chmod u+x "$target"

state_root=${GAME_COMPAT_STEAM_STATE_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/game-compat/steam-compat}
compat_data="$state_root/$bottle_name"
mkdir -p "$compat_data"

launch_options="STEAM_COMPAT_DATA_PATH=\"$compat_data\" %command%"
if [[ -n $dll_overrides ]]; then
    [[ $dll_overrides != *$'\n'* && $dll_overrides != *'"'* ]] || {
        echo 'DLL overrides may not contain quotes or newlines.' >&2; exit 2;
    }
    launch_options="WINEDLLOVERRIDES=\"$dll_overrides\" $launch_options"
fi
for ((i=${#launch_env[@]}-1; i>=0; i--)); do
    name=${launch_env[i]%%=*}
    value=${launch_env[i]#*=}
    [[ $value != *'"'* ]] || { echo "Environment value for $name may not contain quotes." >&2; exit 2; }
    launch_options="$name=\"$value\" $launch_options"
done
if [[ -n $prepare ]]; then
    prepare=$(realpath -e -- "$prepare")
    [[ -x $prepare ]] || { echo "Prepare script is not executable: $prepare" >&2; exit 1; }
    if sed '/^[[:space:]]*#/d' "$prepare" | rg -n -i \
        'bottles-cli|bottles-game\.sh|flatpak[[:space:]]+run|(^|[[:space:]])wine(boot|server|64)?([[:space:]]|$)|/proton([[:space:]]|$)|steam[[:space:]]+-' \
        -; then
        echo 'Preparation scripts may not start Bottles, Wine, Proton or Steam.' >&2
        echo 'Make persistent prefix changes during setup or use an offline file editor.' >&2
        exit 1
    fi
    # Steam tracks the entire shell command. Bound preparation so a broken
    # helper cannot leave the shortcut permanently marked Running.
    launch_options="timeout --foreground --signal=TERM --kill-after=2s 10s \"$prepare\" && $launch_options"
fi

was_running=0
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then was_running=1; fi
args=("$shortcut_name" "$target" --allow-non-executable --launch-options "$launch_options" --no-restart)
[[ -z $artwork ]] || args+=(--artwork-dir "$artwork")
(( yes )) && args+=(--yes)
for name in "${replace_names[@]}"; do args+=(--replace-name "$name"); done
output=$("$root/run-python-tool.sh" add-steam-shortcut.py "${args[@]}")
printf '%s\n' "$output"
app_id=$(sed -n 's/^App ID: //p' <<<"$output")
[[ $app_id =~ ^[0-9]+$ ]] || { echo 'Shortcut was not created; no App ID was returned.' >&2; exit 1; }
launch_id=$(sed -n 's/^Launch ID: //p' <<<"$output")
[[ $launch_id =~ ^[0-9]+$ ]] || { echo 'Shortcut was not created; no non-Steam Launch ID was returned.' >&2; exit 1; }

# A pre-launch helper can run before Proton gets its first chance to initialize
# this directory. Generate Proton's own metadata in a disposable empty prefix,
# then retain only the metadata files and link the real Bottles prefix. No DLL,
# registry, dependency, or game file is copied from the disposable prefix.
if [[ ! -f $compat_data/version || ! -f $compat_data/config_info || ! -f $compat_data/tracked_files ]]; then
    steam_root=$(resolve_steam_root)
    proton="$steam_root/compatibilitytools.d/Proton-GE Latest/proton"
    [[ -x $proton ]] || { echo 'Proton-GE Latest is not installed.' >&2; exit 1; }
    init_dir=$(mktemp -d "$state_root/.proton-metadata-init.XXXXXX")
    cleanup_init() { rm -rf -- "$init_dir"; }
    trap cleanup_init EXIT
    STEAM_COMPAT_DATA_PATH="$init_dir" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_root" \
    SteamAppId=0 SteamGameId=0 "$proton" run wineboot -u
    for metadata in version config_info tracked_files; do
        [[ -f $init_dir/$metadata ]] || { echo "Proton did not create $metadata" >&2; exit 1; }
        cp -a -- "$init_dir/$metadata" "$compat_data/$metadata"
    done
    cleanup_init
    trap - EXIT
fi
if [[ -L $compat_data/pfx ]]; then
    [[ $(readlink -f "$compat_data/pfx") == "$(readlink -f "$bottle")" ]] || {
        echo "Existing prefix link points elsewhere: $compat_data/pfx" >&2; exit 1;
    }
elif [[ -e $compat_data/pfx ]]; then
    echo "Refusing to replace non-symlink prefix state: $compat_data/pfx" >&2; exit 1
else
    ln -s "$bottle" "$compat_data/pfx"
fi

"$root/set-steam-compat-tool.sh" "$app_id" 'Proton-GE Latest'
removed=$(sed -n 's/^Removed App IDs: //p' <<<"$output")
if [[ -n $removed ]]; then
    IFS=, read -r -a removed_ids <<<"$removed"
    "$root/remove-steam-compat-tool.sh" "${removed_ids[@]}"
fi
if (( was_running && restart )); then
    unit="game-compat-steam-restart-$(date +%s)"
    systemd-run --user --unit="$unit" --collect steam -silent >/dev/null
fi
printf 'Steam launch options:\n%s\n' "$launch_options"
printf 'Steam command-line launch:\nsteam steam://rungameid/%s\n' "$launch_id"
printf 'WARNING: Bottles and Steam Proton share this prefix. Snapshot before runner changes.\n'
