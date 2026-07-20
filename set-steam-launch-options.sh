#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$root/lib/steam-paths.sh"

usage() {
    cat <<'EOF'
Usage: set-steam-launch-options.sh [--user-id STEAM_ID] APP_ID 'FULL LAUNCH OPTIONS'

Steam must be stopped. The complete value is replaced, backed up, and verified.
Pass an empty string to clear the launch options.
EOF
}

steam_root=$(resolve_steam_root)
user_id=${STEAM_USER_ID:-}
if [[ ${1:-} == '--user-id' ]]; then
    user_id=${2:?--user-id requires a Steam user ID}
    shift 2
fi
[[ $# -eq 2 ]] || { usage >&2; exit 2; }
app_id=$1
launch_options=$2
[[ $app_id =~ ^[0-9]+$ ]] || { echo 'APP_ID must be numeric.' >&2; exit 2; }

if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Refusing to edit while Steam or steamwebhelper is running.' >&2
    exit 1
fi

if [[ -z $user_id ]]; then
    file=$(steam_localconfig "$steam_root")
else
    file="$steam_root/userdata/$user_id/config/localconfig.vdf"
fi
[[ -f $file ]] || { echo "Not found: $file" >&2; exit 1; }

timestamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$(dirname "$file")/game-compat-backups"
mkdir -p "$backup_dir"
backup="$backup_dir/localconfig.vdf.$timestamp"
cp -a -- "$file" "$backup"

APP_ID=$app_id LAUNCH_OPTIONS=$launch_options perl -i -ne '
    BEGIN { $app=$ENV{APP_ID}; $value=$ENV{LAUNCH_OPTIONS}; $in=0; $depth=0; $seen=0; $found_app=0 }
    if (!$in && /^([ \t]*)"\Q$app\E"\s*$/) {
        $in=1; $await_open=1; $app_field_indent="$1\t";
    }
    if ($in) {
        $found_app=1;
        if ($await_open && /\{/) { $depth=1; $await_open=0 }
        elsif (!$await_open) {
            $depth += tr/{/{/;
            $depth -= tr/}/}/;
        }
        if (!$seen && /^([ \t]*)"LaunchOptions"\s+"(?:[^"\\]|\\.)*"\s*$/) {
            $indent=length($1) ? $1 : $app_field_indent;
            $escaped=$value; $escaped =~ s/\\/\\\\/g; $escaped =~ s/"/\\"/g;
            $_ = qq{$indent"LaunchOptions"\t\t"$escaped"\n}; $seen=1;
        }
        if (!$await_open && $depth == 0) {
            if (!$seen) {
                ($indent) = /^(\s*)\}/;
                $escaped=$value; $escaped =~ s/\\/\\\\/g; $escaped =~ s/"/\\"/g;
                print qq{$indent\t"LaunchOptions"\t\t"$escaped"\n}; $seen=1;
            }
            $in=0;
        }
    }
    print;
    END { exit 4 unless $found_app; exit 3 unless $seen }
' "$file" || {
    status=$?
    cp -a -- "$backup" "$file"
    echo "LaunchOptions for app $app_id was not changed (status $status); backup restored." >&2
    exit "$status"
}

stored=$(APP_ID=$app_id perl -ne '
    if (!$in && /^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $in=1; $await=1 }
    if ($in && /^\s*"LaunchOptions"\s+"((?:[^"\\]|\\.)*)"/) { print $1; exit }
    if ($in && $await && /\{/) { $depth=1; $await=0 }
    elsif ($in && !$await) { $depth += tr/{/{/; $depth -= tr/}/}/; $in=0 if $depth == 0 }
' "$file")
expected=${launch_options//\/\\}
expected=${expected//\"/\\\"}
[[ $stored == "$expected" ]] || {
    cp -a -- "$backup" "$file"
    echo 'Verification failed; backup restored.' >&2
    exit 1
}

echo "Updated app $app_id in $file"
echo "Backup: $backup"
printf 'Full launch options: %s\n' "$launch_options"
