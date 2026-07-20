#!/usr/bin/env bash

# shellcheck source=load-env.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/load-env.sh"

resolve_steam_root() {
    local candidate
    if [[ -n ${STEAM_ROOT:-} ]]; then
        candidate=$STEAM_ROOT
    elif [[ -d $HOME/.local/share/Steam ]]; then
        candidate=$HOME/.local/share/Steam
    elif [[ -d $HOME/.steam/steam ]]; then
        candidate=$HOME/.steam/steam
    else
        echo 'Steam root not found. Set STEAM_ROOT to your Steam directory.' >&2
        return 1
    fi
    realpath -e -- "$candidate"
}

steam_library_roots() {
    local steam_root=$1 library_file
    library_file="$steam_root/steamapps/libraryfolders.vdf"
    printf '%s\0' "$steam_root"
    [[ -f $library_file ]] || return 0
    perl -ne 'if (/^\s*"path"\s+"((?:[^"\\]|\\.)*)"/) { $p=$1; $p =~ s/\\\\/\\/g; print "$p\0" }' \
        "$library_file"
}

steam_app_library_dir() {
    local steam_root=$1 app_id=$2 library manifest install_dir
    while IFS= read -r -d '' library; do
        manifest="$library/steamapps/appmanifest_${app_id}.acf"
        [[ -f $manifest ]] || continue
        install_dir=$(perl -ne 'if (/^\s*"installdir"\s+"((?:[^"\\]|\\.)*)"/) { print $1; exit }' "$manifest")
        [[ -n $install_dir && -d "$library/steamapps/common/$install_dir" ]] || continue
        realpath -e -- "$library"
        return 0
    done < <(steam_library_roots "$steam_root")
    echo "Installed Steam App ID $app_id was not found in configured libraries." >&2
    return 1
}

steam_app_install_dir() {
    local steam_root=$1 app_id=$2 library manifest install_dir
    library=$(steam_app_library_dir "$steam_root" "$app_id")
    manifest="$library/steamapps/appmanifest_${app_id}.acf"
    install_dir=$(perl -ne 'if (/^\s*"installdir"\s+"((?:[^"\\]|\\.)*)"/) { print $1; exit }' "$manifest")
    realpath -e -- "$library/steamapps/common/$install_dir"
}

steam_app_compatdata_dir() {
    local steam_root=$1 app_id=$2 library
    library=$(steam_app_library_dir "$steam_root" "$app_id")
    printf '%s\n' "$library/steamapps/compatdata/$app_id"
}

steam_launch_options() {
    local localconfig=$1 app_id=$2
    APP_ID=$app_id perl -ne '
        if (!$in && /^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $in=1; $await=1 }
        if ($in && /^\s*"LaunchOptions"\s+"((?:[^"\\]|\\.)*)"/) {
            $v=$1; $v =~ s/\\"/"/g; $v =~ s/\\\\/\\/g; print $v; exit
        }
        if ($in && $await && /\{/) { $depth=1; $await=0 }
        elsif ($in && !$await) { $depth += tr/{/{/; $depth -= tr/}/}/; $in=0 if $depth == 0 }
    ' "$localconfig"
}

steam_controller_configs() {
    local steam_root=$1 base
    base="$steam_root/steamapps/common/Steam Controller Configs"
    [[ -d $base ]] || return 0
    find "$base" -mindepth 3 -maxdepth 3 -type f \
        -path '*/config/configset_controller_xboxone.vdf' -print0 | sort -z
}

controller_config_fingerprint() {
    local steam_root=$1 file found=0
    local -a lines=()
    while IFS= read -r -d '' file; do
        found=1
        lines+=("$(sha256sum "$file")")
    done < <(steam_controller_configs "$steam_root")
    if ((found == 0)); then
        printf 'absent\n'
    else
        printf '%s\n' "${lines[@]}" | sha256sum | cut -d' ' -f1
    fi
}

steam_localconfig() {
    local steam_root=$1
    local -a candidates=()
    if [[ -n ${STEAM_USER_ID:-} ]]; then
        local selected="$steam_root/userdata/$STEAM_USER_ID/config/localconfig.vdf"
        [[ -f $selected ]] || { echo "Steam local config not found: $selected" >&2; return 1; }
        printf '%s\n' "$selected"
        return
    fi
    mapfile -t candidates < <(find "$steam_root/userdata" -mindepth 3 -maxdepth 3 \
        -path '*/config/localconfig.vdf' -print 2>/dev/null | sort)
    [[ ${#candidates[@]} -eq 1 ]] || {
        echo "Found ${#candidates[@]} Steam local configs; set STEAM_USER_ID explicitly." >&2
        return 1
    }
    printf '%s\n' "${candidates[0]}"
}
