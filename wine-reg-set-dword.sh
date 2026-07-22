#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: wine-reg-set-dword.sh BOTTLE KEY VALUE DATA

Set one DWORD in an inactive Bottles Flatpak prefix without starting Wine.
DATA must be exactly eight hexadecimal digits, for example ffffffff.
EOF
}

[[ $# -eq 4 ]] || { usage >&2; exit 2; }
bottle_name=$1
key=$2
value=$3
data=${4,,}
[[ $bottle_name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || {
    echo "Invalid bottle name: $bottle_name" >&2; exit 2;
}
[[ $key != *$'\n'* && $key != *'['* && $key != *']'* ]] || {
    echo 'Registry key contains unsupported characters.' >&2; exit 2;
}
value_pattern='^[A-Za-z0-9_. -]+$'
[[ $value =~ $value_pattern ]] || {
    echo 'Registry value name contains unsupported characters.' >&2; exit 2;
}
[[ $data =~ ^[0-9a-f]{8}$ ]] || {
    echo 'DWORD data must be exactly eight hexadecimal digits.' >&2; exit 2;
}

bottles_root=${BOTTLES_ROOT:-"${XDG_DATA_HOME:-$HOME/.local/share}/bottles/bottles"}
flatpak_root="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"
if [[ ! -d $bottles_root && -d $flatpak_root ]]; then
    bottles_root=$flatpak_root
fi
prefix="$bottles_root/$bottle_name"
registry="$prefix/user.reg"
[[ -f $prefix/bottle.yml && -f $registry ]] || {
    echo "Bottle registry was not found: $registry" >&2; exit 1;
}

for proc in /proc/[0-9]*; do
    [[ -r $proc/environ ]] || continue
    if (cat "$proc/environ" 2>/dev/null || true) | tr '\0' '\n' |
        grep -Fqx "WINEPREFIX=$prefix"; then
        echo "Bottle is active (PID ${proc##*/}); registry was not edited." >&2
        exit 1
    fi
done

escaped_key=$(printf '%s' "$key" | sed 's/\\/\\\\/g')
header="[$escaped_key]"
replacement="\"$value\"=dword:$data"
value_prefix="\"$value\"="
lock="$registry.game-compat.lock"
exec 9>"$lock"
flock -w 5 9 || { echo "Could not lock: $registry" >&2; exit 1; }

temporary=$(mktemp --tmpdir="$(dirname -- "$registry")" user.reg.XXXXXX)
cleanup() { rm -f -- "$temporary"; }
trap cleanup EXIT
HEADER="$header" VALUE_PREFIX="$value_prefix" REPLACEMENT="$replacement" awk '
    BEGIN {
        header=ENVIRON["HEADER"]
        value=ENVIRON["VALUE_PREFIX"]
        replacement=ENVIRON["REPLACEMENT"]
    }
    index($0, header) == 1 { in_key=1; found_key=1; print; next }
    in_key && index($0, value) == 1 { print replacement; found_value=1; next }
    in_key && /^\[/ {
        if (!found_value) print replacement
        in_key=0
    }
    { print }
    END {
        if (!found_key) exit 20
        if (in_key && !found_value) print replacement
    }
' "$registry" >"$temporary" || {
    status=$?
    [[ $status -ne 20 ]] || echo "Registry key was not found: $key" >&2
    exit "$status"
}

cp -a -- "$registry" "$registry.game-compat.bak"
chmod --reference="$registry" "$temporary"
mv -f -- "$temporary" "$registry"
trap - EXIT
grep -Fqx -- "$replacement" "$registry" || {
    echo 'Registry verification failed.' >&2; exit 1;
}
echo "Updated inactive bottle registry: $bottle_name / $key / $value"
