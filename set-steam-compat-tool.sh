#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$root/lib/steam-paths.sh"

usage() {
    cat <<'EOF'
Usage: set-steam-compat-tool.sh APP_ID 'STEAM COMPAT TOOL NAME'

Steam must be stopped. Changes only the requested App ID inside
CompatToolMapping, keeps a timestamped backup, and verifies the stored name.
Examples: 'Proton-GE Latest', 'proton_experimental', 'GE-Proton10-34'.
EOF
}

[[ $# -eq 2 ]] || { usage >&2; exit 2; }
app_id=$1
tool_name=$2
[[ $app_id =~ ^[0-9]+$ ]] || { echo 'APP_ID must be numeric.' >&2; exit 2; }
[[ -n $tool_name && $tool_name != *$'\n'* && $tool_name != *$'\t'* ]] || {
    echo 'Tool name must be non-empty and contain no tabs/newlines.' >&2; exit 2;
}

if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Refusing to edit while Steam or steamwebhelper is running.' >&2
    exit 1
fi

steam_root=$(resolve_steam_root)
file="$steam_root/config/config.vdf"
[[ -f $file ]] || { echo "Not found: $file" >&2; exit 1; }
backup_dir="$(dirname "$file")/game-compat-backups"
mkdir -p "$backup_dir"
backup="$backup_dir/config.vdf.$(date +%Y%m%d-%H%M%S-%N)"
cp -a -- "$file" "$backup"

APP_ID=$app_id TOOL_NAME=$tool_name perl -i -ne '
    BEGIN {
        $app=$ENV{APP_ID}; $value=$ENV{TOOL_NAME};
        $compat=0; $compat_wait=0; $compat_depth=0;
        $in_app=0; $app_wait=0; $app_depth=0;
        $app_seen=0; $name_seen=0; $compat_seen=0;
        $escaped=$value; $escaped =~ s/\\/\\\\/g; $escaped =~ s/"/\\"/g;
    }
    if (!$compat && !$compat_wait && /^\s*"CompatToolMapping"\s*$/) {
        $compat_wait=1; print; next;
    }
    if ($compat_wait) {
        print;
        if (/^([ \t]*)\{/) {
            $compat=1; $compat_wait=0; $compat_depth=1;
            $entry_indent="$1\t"; $field_indent="$1\t\t";
            $compat_seen=1;
        }
        next;
    }
    if ($compat) {
        $opens = tr/{/{/; $closes = tr/}/}/;
        if (!$in_app && /^\s*"\Q$app\E"\s*$/) {
            $in_app=1; $app_wait=1; $app_seen=1;
        }
        if ($in_app && $app_wait && $opens) {
            $app_wait=0; $app_depth=$opens-$closes;
        } elsif ($in_app && !$app_wait) {
            if (!$name_seen && $app_depth == 1 && $closes && !$opens) {
                print qq{$field_indent"name"\t\t"$escaped"\n};
                print qq{$field_indent"config"\t\t""\n};
                print qq{$field_indent"priority"\t\t"250"\n};
                $name_seen=1;
            }
            $app_depth += $opens-$closes;
        }
        if ($in_app && /^([ \t]*)"name"\s+"(?:[^"\\]|\\.)*"\s*$/) {
            $_=qq{$1"name"\t\t"$escaped"\n}; $name_seen=1;
        }
        if (!$app_seen && $compat_depth == 1 && $closes && !$opens) {
            print qq{$entry_indent"$app"\n};
            print $entry_indent . "{\n";
            print qq{$field_indent"name"\t\t"$escaped"\n};
            print qq{$field_indent"config"\t\t""\n};
            print qq{$field_indent"priority"\t\t"250"\n};
            print $entry_indent . "}\n";
            $app_seen=1; $name_seen=1;
        }
        print;
        $compat_depth += $opens-$closes;
        $in_app=0 if $in_app && !$app_wait && $app_depth == 0;
        $compat=0 if $compat_depth == 0;
        next;
    }
    print;
    END { exit 4 unless $compat_seen; exit 3 unless $app_seen && $name_seen }
' "$file" || {
    status=$?; cp -a -- "$backup" "$file"
    echo "CompatToolMapping for app $app_id was not changed (status $status); backup restored." >&2
    exit "$status"
}

stored=$(APP_ID=$app_id perl -ne '
    if (!$compat && /^\s*"CompatToolMapping"\s*$/) { $compat=1 }
    if ($compat && !$app && /^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $app=1 }
    if ($app && /^\s*"name"\s+"([^"]*)"/) { print $1; exit }
' "$file")
[[ $stored == "$tool_name" ]] || {
    cp -a -- "$backup" "$file"
    echo "Verification failed (stored '$stored'); backup restored." >&2
    exit 1
}

echo "Updated app $app_id compatibility tool to: $tool_name"
echo "Backup: $backup"
