#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bottles-game.sh status
  bottles-game.sh list
  bottles-game.sh path [BOTTLE]
  bottles-game.sh config BOTTLE
  bottles-game.sh fingerprint BOTTLE
  bottles-game.sh snapshot BOTTLE ARCHIVE.tar.zst
  bottles-game.sh ensure BOTTLE [win32|win64] [gaming|application|custom]
  bottles-game.sh add BOTTLE PROGRAM_NAME WINDOWS_EXE [LAUNCH_OPTIONS]
  bottles-game.sh programs BOTTLE
  bottles-game.sh run BOTTLE PROGRAM_NAME [ARG...]
  bottles-game.sh run-exe BOTTLE WINDOWS_EXE [ARG...]
  bottles-game.sh stop BOTTLE [--yes]

Reusable Bottles-only management for non-Steam Windows cases. One case should
use one stable lowercase bottle name. This tool never creates a raw Wine prefix,
never removes a bottle, and never installs host or kernel packages.
EOF
}

die() { echo "$*" >&2; exit 1; }
valid_bottle() { [[ $1 =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "Invalid bottle name: $1"; }

bottle_root() { "${cli[@]}" info bottles-path; }
bottle_path() {
    valid_bottle "$1"
    printf '%s/%s\n' "$(bottle_root)" "$1"
}
require_bottle() {
    local path
    path=$(bottle_path "$1")
    [[ -f $path/bottle.yml ]] || die "Bottle does not exist: $1"
    printf '%s\n' "$path"
}
active_bottle_pids() {
    local path=$1 proc env
    for proc in /proc/[0-9]*; do
        [[ -r $proc/environ ]] || continue
        env=$( (tr '\0' '\n' <"$proc/environ") 2>/dev/null || true)
        if grep -Fqx "WINEPREFIX=$path" <<<"$env"; then
            printf '%s\n' "${proc##*/}"
        fi
    done
}

flatpak info com.usebottles.bottles >/dev/null 2>&1 ||
    die 'The officially supported Bottles Flatpak (com.usebottles.bottles) is not installed or initialized.'
cli=(flatpak run --command=bottles-cli com.usebottles.bottles)
backend=flatpak

command=${1:-}
[[ -n $command ]] || { usage; exit 2; }
shift

case $command in
    status)
        [[ $# -eq 0 ]] || { usage >&2; exit 2; }
        echo "backend=$backend"
        "${cli[@]}" --version
        "${cli[@]}" info bottles-path
        "${cli[@]}" info health-check
        ;;
    list)
        [[ $# -eq 0 ]] || { usage >&2; exit 2; }
        "${cli[@]}" list bottles
        ;;
    path)
        [[ $# -le 1 ]] || { usage >&2; exit 2; }
        if [[ $# -eq 1 ]]; then bottle_path "$1"; else bottle_root; fi
        ;;
    config)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        path=$(require_bottle "$1")
        sed -n '1,240p' "$path/bottle.yml"
        ;;
    fingerprint)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        path=$(require_bottle "$1")
        (
            cd "$path"
            find . -type f \
                ! -path './logs/*' ! -name '.update-timestamp' -print0 |
                sort -z |
                xargs -0 -r sha256sum
        ) | sha256sum | awk '{print $1}'
        ;;
    snapshot)
        [[ $# -eq 2 ]] || { usage >&2; exit 2; }
        bottle=$1; archive=$2
        path=$(require_bottle "$bottle")
        [[ $archive == *.tar.zst ]] || die 'Snapshot name must end in .tar.zst'
        [[ ! -e $archive ]] || die "Refusing to overwrite: $archive"
        mapfile -t pids < <(active_bottle_pids "$path")
        ((${#pids[@]} == 0)) || die "Bottle is running (PID(s): ${pids[*]}). Close it before snapshotting."
        command -v zstd >/dev/null || die 'zstd is required for snapshots.'
        mkdir -p "$(dirname "$archive")"
        tar --zstd -C "$(dirname "$path")" -cf "$archive" "$(basename "$path")"
        sha256sum "$archive" >"$archive.sha256"
        printf 'Snapshot: %s\nChecksum: %s\n' "$archive" "$archive.sha256"
        ;;
    ensure)
        [[ $# -ge 1 && $# -le 3 ]] || { usage >&2; exit 2; }
        bottle=$1; arch=${2:-win64}; environment=${3:-gaming}
        valid_bottle "$bottle"
        [[ $arch == win32 || $arch == win64 ]] || die "Unsupported architecture: $arch"
        [[ $environment == gaming || $environment == application || $environment == custom ]] || die "Unsupported environment: $environment"
        root=$("${cli[@]}" info bottles-path)
        if [[ -f $root/$bottle/bottle.yml ]]; then
            configured_arch=$(sed -n 's/^Arch: //p' "$root/$bottle/bottle.yml" | head -n 1)
            [[ $configured_arch == "$arch" ]] || die \
                "Bottle $bottle already exists as ${configured_arch:-an unknown architecture}; requested $arch. Bottle architectures cannot be converted in place."
            echo "Bottle already exists: $bottle"
        else
            "${cli[@]}" new --bottle-name "$bottle" --environment "$environment" --arch "$arch"
        fi
        [[ -f $root/$bottle/bottle.yml ]] || die "Bottle creation did not produce $root/$bottle/bottle.yml"
        echo "Bottle ready: $root/$bottle"
        ;;
    add)
        [[ $# -ge 3 && $# -le 4 ]] || { usage >&2; exit 2; }
        bottle=$1; name=$2; exe=$3; options=${4:-}
        valid_bottle "$bottle"
        args=(add -b "$bottle" -n "$name" -p "$exe")
        [[ -z $options ]] || args+=(-l "$options")
        "${cli[@]}" "${args[@]}"
        ;;
    programs)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        valid_bottle "$1"
        "${cli[@]}" programs -b "$1"
        ;;
    run)
        [[ $# -ge 2 ]] || { usage >&2; exit 2; }
        bottle=$1; program=$2; shift 2
        valid_bottle "$bottle"
        "${cli[@]}" run -b "$bottle" -p "$program" --args-replace "$@"
        ;;
    run-exe)
        [[ $# -ge 2 ]] || { usage >&2; exit 2; }
        bottle=$1; exe=$2; shift 2
        valid_bottle "$bottle"
        "${cli[@]}" run -b "$bottle" -e "$exe" --args-replace "$@"
        ;;
    stop)
        [[ $# -ge 1 && $# -le 2 ]] || { usage >&2; exit 2; }
        bottle=$1
        yes=0
        if [[ ${2:-} == --yes ]]; then yes=1
        elif [[ $# -eq 2 ]]; then usage >&2; exit 2
        fi
        require_bottle "$bottle" >/dev/null
        echo "WARNING: this stops every Wine process in bottle $bottle." >&2
        echo 'Unsaved game data may be lost. Other bottles and Steam are not stopped.' >&2
        if (( ! yes )); then
            read -r -p 'Stop this bottle through Wine now? [y/N] ' answer
            [[ $answer == [yY] ]] || exit 0
        fi
        "${cli[@]}" shell -b "$bottle" -i 'wineboot -k /nogui'
        ;;
    -h|--help|help) usage ;;
    *) echo "Unknown command: $command" >&2; usage >&2; exit 2 ;;
esac
