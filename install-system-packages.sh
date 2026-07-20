#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=0
distro=''

discover_game_manifests() {
    find "$root" \
        \( -path "$root/.git" -o -path "$root/_*" -o -path "$root/skills" \
           -o -name logs -o -name evidence -o -name configs -o -name runtime \
           -o -name source -o -name prefixes -o -name tool-downloads \) -prune \
        -o -type f -name requirements.txt -print0 | sort -z
}

usage() {
    cat <<'EOF'
Usage: install-system-packages.sh [--dry-run] [--distro DISTRO] [all|global|GAME...]

Supported DISTRO values: arch, ubuntu, fedora. Detection uses /etc/os-release.
Arch uses yay when available and otherwise pacman. Ubuntu/Debian use apt-get;
Fedora uses dnf. With no selector, global plus all game requirements are used.
Selecting games includes global requirements automatically.

Selectors are discovered from every case requirements.txt. Run with --help to
print the selectors available in the current checkout.
EOF
    local manifest aliases
    printf '\nDiscovered requirement manifests:\n'
    while IFS= read -r -d '' manifest; do
        aliases=$(sed -n 's/^# selectors:[[:space:]]*//p' "$manifest" | head -n 1)
        printf '  %-45s %s\n' "${manifest#"$root/"}" "$aliases"
    done < <(discover_game_manifests)
}

while [[ ${1:-} == --* ]]; do
    case $1 in
        --dry-run) dry_run=1; shift ;;
        --distro) distro=${2:?--distro requires arch, ubuntu, or fedora}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z $distro ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    family="${ID:-} ${ID_LIKE:-}"
    case " $family " in
        *' arch '*) distro=arch ;;
        *' ubuntu '*|*' debian '*) distro=ubuntu ;;
        *' fedora '*|*' rhel '*) distro=fedora ;;
        *) echo "Unsupported distribution family: $family. Use --distro for a dry run." >&2; exit 1 ;;
    esac
fi
[[ $distro == arch || $distro == ubuntu || $distro == fedora ]] || {
    echo "Unsupported distro: $distro" >&2; exit 2;
}

declare -a manifests=()
mapfile -d '' -t game_manifests < <(discover_game_manifests)
add_manifest() {
    local candidate=$1 existing
    for existing in "${manifests[@]}"; do [[ $existing == "$candidate" ]] && return; done
    manifests+=("$candidate")
}
add_game_manifest() { add_manifest "$root/requirements-global.txt"; add_manifest "$1"; }

select_game() {
    local selector=$1 manifest rel base aliases alias
    local -a matches=()
    for manifest in "${game_manifests[@]}"; do
        rel=${manifest#"$root/"}; rel=${rel%/requirements.txt}; base=${rel##*/}
        aliases=$(sed -n 's/^# selectors:[[:space:]]*//p' "$manifest" | head -n 1)
        if [[ $selector == "$rel" || $selector == "$base" ]]; then
            matches+=("$manifest"); continue
        fi
        for alias in $aliases; do
            [[ $selector == "$alias" ]] && { matches+=("$manifest"); break; }
        done
    done
    [[ ${#matches[@]} -eq 1 ]] || {
        echo "Selector '$selector' matched ${#matches[@]} game manifests." >&2
        usage >&2
        exit 2
    }
    add_game_manifest "${matches[0]}"
}

if [[ $# -eq 0 || ${1:-} == all ]]; then
    [[ $# -le 1 ]] || { usage >&2; exit 2; }
    add_manifest "$root/requirements-global.txt"
    for manifest in "${game_manifests[@]}"; do add_game_manifest "$manifest"; done
else
    for selector in "$@"; do
        case $selector in
            global) add_manifest "$root/requirements-global.txt" ;;
            *) select_game "$selector" ;;
        esac
    done
fi

map_capability() {
    local key="$distro:$1"
    case $key in
        arch:curl|ubuntu:curl|fedora:curl) echo curl ;;
        arch:unzip|ubuntu:unzip|fedora:unzip) echo unzip ;;
        arch:file|ubuntu:file|fedora:file) echo file ;;
        arch:python3) echo python ;;
        ubuntu:python3|fedora:python3) echo python3 ;;
        arch:python-tk) echo tk ;;
        ubuntu:python-tk) echo python3-tk ;;
        fedora:python-tk) echo python3-tkinter ;;
        arch:python-venv) echo python ;;
        ubuntu:python-venv) echo python3-venv ;;
        fedora:python-venv) echo python3 ;;
        arch:kdotool|fedora:kdotool) echo kdotool ;;
        ubuntu:kdotool) echo '' ;;
        arch:xdotool|ubuntu:xdotool|fedora:xdotool) echo xdotool ;;
        arch:xprop) echo xorg-xprop ;;
        ubuntu:xprop) echo x11-utils ;;
        fedora:xprop) echo xprop ;;
        arch:imagemagick|ubuntu:imagemagick) echo imagemagick ;;
        fedora:imagemagick) echo ImageMagick ;;
        arch:spectacle|fedora:spectacle) echo spectacle ;;
        ubuntu:spectacle) echo kde-spectacle ;;
        arch:vulkan-tools|ubuntu:vulkan-tools|fedora:vulkan-tools) echo vulkan-tools ;;
        arch:ffmpeg|ubuntu:ffmpeg) echo ffmpeg ;;
        fedora:ffmpeg) echo ffmpeg-free ;;
        arch:mpv|ubuntu:mpv|fedora:mpv) echo mpv ;;
        arch:mangohud|ubuntu:mangohud|fedora:mangohud) echo mangohud ;;
        arch:mangohud-32bit) echo lib32-mangohud ;;
        ubuntu:mangohud-32bit) echo 'mangohud:i386' ;;
        fedora:mangohud-32bit) echo 'mangohud.i686' ;;
        arch:c-compiler|ubuntu:c-compiler|fedora:c-compiler) echo gcc ;;
        arch:gstreamer-tools) echo gstreamer ;;
        ubuntu:gstreamer-tools) echo gstreamer1.0-tools ;;
        fedora:gstreamer-tools) echo gstreamer1 ;;
        arch:gstreamer-plugins-base) echo gst-plugins-base ;;
        ubuntu:gstreamer-plugins-base) echo gstreamer1.0-plugins-base ;;
        fedora:gstreamer-plugins-base) echo gstreamer1-plugins-base ;;
        arch:gstreamer-plugins-good) echo gst-plugins-good ;;
        ubuntu:gstreamer-plugins-good) echo gstreamer1.0-plugins-good ;;
        fedora:gstreamer-plugins-good) echo gstreamer1-plugins-good ;;
        arch:gstreamer-plugins-bad) echo gst-plugins-bad ;;
        ubuntu:gstreamer-plugins-bad) echo gstreamer1.0-plugins-bad ;;
        fedora:gstreamer-plugins-bad) echo gstreamer1-plugins-bad-free ;;
        arch:gstreamer-plugins-ugly) echo gst-plugins-ugly ;;
        ubuntu:gstreamer-plugins-ugly) echo gstreamer1.0-plugins-ugly ;;
        fedora:gstreamer-plugins-ugly) echo gstreamer1-plugins-ugly-free ;;
        arch:gstreamer-libav) echo gst-libav ;;
        ubuntu:gstreamer-libav) echo gstreamer1.0-libav ;;
        fedora:gstreamer-libav) echo gstreamer1-plugin-libav ;;
        arch:nrg2iso|ubuntu:nrg2iso|fedora:nrg2iso) echo nrg2iso ;;
        arch:iso-info) echo cdrtools ;;
        ubuntu:iso-info|fedora:iso-info) echo genisoimage ;;
        arch:libarchive) echo libarchive ;;
        ubuntu:libarchive) echo libarchive-tools ;;
        fedora:libarchive) echo bsdtar ;;
        arch:ripgrep|ubuntu:ripgrep|fedora:ripgrep) echo ripgrep ;;
        *) echo "No $distro package mapping for capability: $1" >&2; return 1 ;;
    esac
}

capabilities=()
declare -A seen_capability=()
for manifest in "${manifests[@]}"; do
    [[ -f $manifest ]] || { echo "Requirements manifest not found: $manifest" >&2; exit 1; }
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%%#*}; read -r -a fields <<< "$line"
        for capability in "${fields[@]}"; do
            [[ $capability =~ ^[a-z0-9][a-z0-9.+-]*$ ]] || {
                echo "Invalid capability in $manifest: $capability" >&2; exit 1;
            }
            if [[ ! -v seen_capability[$capability] ]]; then
                capabilities+=("$capability"); seen_capability[$capability]=1
            fi
        done
    done < "$manifest"
done

packages=()
declare -A seen_package=()
for capability in "${capabilities[@]}"; do
    mapped=$(map_capability "$capability")
    if [[ -z $mapped ]]; then
        echo "Note: $capability is optional/unavailable in the standard $distro repositories; using fallback tooling." >&2
        continue
    fi
    read -r -a fields <<< "$mapped"
    for package in "${fields[@]}"; do
        if [[ ! -v seen_package[$package] ]]; then packages+=("$package"); seen_package[$package]=1; fi
    done
done
[[ ${#packages[@]} -gt 0 ]] || { echo 'No packages found for selected requirements.' >&2; exit 1; }

case $distro in
    arch)
        if command -v yay >/dev/null; then command=(yay -S --needed --)
        else command=(sudo pacman -S --needed --); fi ;;
    ubuntu) command=(sudo apt-get install -y --) ;;
    fedora) command=(sudo dnf install -y --) ;;
esac

printf 'Distribution: %s\nRequirements manifests:\n' "$distro"
printf '  %s\n' "${manifests[@]}"
printf 'Installing/verifying %d unique packages:\n' "${#packages[@]}"
printf '  %s\n' "${packages[@]}"
printf 'Command:'; printf ' %q' "${command[@]}" "${packages[@]}"; printf '\n'
((dry_run)) && exit 0
exec "${command[@]}" "${packages[@]}"
