#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if ! python3 -c 'import tkinter' 2>/dev/null; then
    # shellcheck disable=SC1091
    source /etc/os-release
    family="${ID:-} ${ID_LIKE:-}"
    case " $family " in
        *' arch '*)
            if command -v yay >/dev/null; then command=(yay -S --needed -- tk)
            else command=(sudo pacman -S --needed -- tk); fi ;;
        *' ubuntu '*|*' debian '*) command=(sudo apt-get install -y -- python3-tk) ;;
        *' fedora '*|*' rhel '*) command=(sudo dnf install -y -- python3-tkinter) ;;
        *)
            echo 'The graphical launcher needs the Python Tk package.' >&2
            echo 'Install it with your distribution package manager, then run this file again.' >&2
            exit 1 ;;
    esac
    echo 'The graphical launcher needs one additional system package.'
    printf 'Command:'; printf ' %q' "${command[@]}"; printf '\n'
    read -r -p 'Install it now? This may ask for your sudo password. [y/N] ' answer
    [[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { echo 'Cancelled.'; exit 0; }
    "${command[@]}"
    python3 -c 'import tkinter' 2>/dev/null || {
        echo 'Python Tk is still unavailable after package installation.' >&2
        exit 1
    }
fi
exec python3 "$root/game-compat-launcher.py" "$@"
