#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  game-config-snapshot.sh backup  GAME_DIR LABEL CONFIG_FILE...
  game-config-snapshot.sh fingerprint GAME_DIR CONFIG_FILE...
  game-config-snapshot.sh list    GAME_DIR
  game-config-snapshot.sh verify  GAME_DIR SNAPSHOT_NAME
  game-config-snapshot.sh diff    GAME_DIR SNAPSHOT_NAME
  game-config-snapshot.sh restore GAME_DIR SNAPSHOT_NAME
  game-config-snapshot.sh set     GAME_DIR CONFIG_FILE KEY VALUE

Snapshots live in GAME_DIR/configs/snapshots/. Each has a TSV manifest mapping
the stored copy to its exact original absolute path plus a SHA-256 digest.
An already-snapshotted identical state exits 10 instead of creating a duplicate.
The game must be stopped before restore. Existing targets receive timestamped
pre-restore copies in GAME_DIR/configs/restore-backups/.
The set action replaces exactly one existing INI-style `KEY = VALUE` line,
backs up the complete file, and verifies the resulting value.
EOF
}

[[ $# -ge 2 ]] || { usage >&2; exit 2; }
action=$1
game_dir=$(realpath -e -- "$2")
shift 2
case_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
[[ $game_dir == "$case_root"/* ]] || {
    echo "GAME_DIR must be a game case below $case_root." >&2; exit 2;
}
config_root="$game_dir/configs"
snapshot_root="$config_root/snapshots"
mkdir -p "$snapshot_root"

resolve_snapshot() {
    [[ $1 != */* && $1 != .* ]] || { echo 'SNAPSHOT_NAME must be a simple name.' >&2; exit 2; }
    snapshot="$snapshot_root/$1"
    [[ -f $snapshot/manifest.tsv ]] || { echo "Snapshot not found: $1" >&2; exit 1; }
}

verify_snapshot() {
    local failed=0 stored source digest actual
    while IFS=$'\t' read -r stored source digest; do
        [[ $stored == stored_file ]] && continue
        actual=$(sha256sum "$snapshot/$stored" | cut -d' ' -f1)
        if [[ $actual != "$digest" ]]; then
            echo "Digest mismatch: $stored" >&2; failed=1
        fi
    done < "$snapshot/manifest.tsv"
    return "$failed"
}

case $action in
    backup)
        [[ $# -ge 2 ]] || { usage >&2; exit 2; }
        label=$1; shift
        safe_label=$(printf %s "$label" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-*//;s/-*$//')
        [[ -n $safe_label ]] || { echo 'LABEL has no usable characters.' >&2; exit 2; }
        name="$(date +%Y%m%d-%H%M%S)-$safe_label"
        tmp=$(mktemp -d "$config_root/.snapshot.XXXXXX")
        trap 'rm -rf -- "$tmp"' EXIT
        printf 'stored_file\tsource_path\tsha256\n' > "$tmp/manifest.tsv"
        index=0
        for source in "$@"; do
            source=$(realpath -e -- "$source")
            [[ -f $source ]] || { echo "Not a regular file: $source" >&2; exit 1; }
            [[ $source != *$'\n'* && $source != *$'\t'* ]] || { echo 'Unsupported path characters.' >&2; exit 1; }
            index=$((index + 1))
            stored=$(printf '%03d-%s' "$index" "$(basename "$source")")
            cp -a -- "$source" "$tmp/$stored"
            digest=$(sha256sum "$tmp/$stored" | cut -d' ' -f1)
            printf '%s\t%s\t%s\n' "$stored" "$source" "$digest" >> "$tmp/manifest.tsv"
        done
        state=$(tail -n +2 "$tmp/manifest.tsv" | cut -f2-3 | sort | sha256sum | cut -d' ' -f1)
        printf '%s\n' "$state" > "$tmp/state.sha256"
        duplicate=''
        while IFS= read -r candidate; do
            [[ -f $candidate/state.sha256 ]] || continue
            [[ $(<"$candidate/state.sha256") == "$state" ]] || continue
            duplicate=${candidate##*/}; break
        done < <(find "$snapshot_root" -mindepth 1 -maxdepth 1 -type d -print | sort)
        if [[ -n $duplicate ]]; then
            echo "DUPLICATE CONFIG STATE: $state" >&2
            echo "Existing snapshot: $duplicate" >&2
            exit 10
        fi
        mv -- "$tmp" "$snapshot_root/$name"
        trap - EXIT
        echo "Created config snapshot: $name"
        echo "Config state: $state"
        ;;
    fingerprint)
        [[ $# -ge 1 ]] || { usage >&2; exit 2; }
        tmp=$(mktemp)
        trap 'rm -f -- "$tmp"' EXIT
        for source in "$@"; do
            source=$(realpath -e -- "$source")
            printf '%s\t%s\n' "$source" "$(sha256sum "$source" | cut -d' ' -f1)" >> "$tmp"
        done
        sort -o "$tmp" "$tmp"
        sha256sum "$tmp" | cut -d' ' -f1
        ;;
    list)
        [[ $# -eq 0 ]] || { usage >&2; exit 2; }
        find "$snapshot_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
        ;;
    verify)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        resolve_snapshot "$1"; verify_snapshot
        echo "Verified config snapshot: $1"
        ;;
    diff)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        resolve_snapshot "$1"; verify_snapshot
        status=0
        while IFS=$'\t' read -r stored source digest; do
            [[ $stored == stored_file ]] && continue
            if [[ -e $source ]]; then
                diff -u --label "snapshot/$stored" --label "$source" "$snapshot/$stored" "$source" || status=1
            else
                echo "Missing live config: $source"; status=1
            fi
        done < "$snapshot/manifest.tsv"
        exit "$status"
        ;;
    restore)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        resolve_snapshot "$1"; verify_snapshot
        backup="$config_root/restore-backups/$(date +%Y%m%d-%H%M%S)-from-$1"
        mkdir -p "$backup"
        while IFS=$'\t' read -r stored source digest; do
            [[ $stored == stored_file ]] && continue
            mkdir -p -- "$(dirname "$source")"
            if [[ -e $source ]]; then cp -a -- "$source" "$backup/$stored"; fi
            cp -a -- "$snapshot/$stored" "$source"
            [[ $(sha256sum "$source" | cut -d' ' -f1) == "$digest" ]] || {
                echo "Restore verification failed: $source" >&2; exit 1;
            }
            echo "Restored: $source"
        done < "$snapshot/manifest.tsv"
        echo "Pre-restore copies: $backup"
        ;;
    set)
        [[ $# -eq 3 ]] || { usage >&2; exit 2; }
        source=$(realpath -e -- "$1")
        key=$2
        value=$3
        [[ -f $source ]] || { echo "Not a regular file: $source" >&2; exit 1; }
        [[ $key =~ ^[A-Za-z0-9_.-]+$ ]] || { echo 'KEY contains unsupported characters.' >&2; exit 2; }
        [[ $value != *$'\n'* && $value != *$'\t'* ]] || { echo 'VALUE must be one line.' >&2; exit 2; }
        count=$(KEY="$key" perl -ne '$n++ if /^\s*\Q$ENV{KEY}\E\s*=/; END { print $n || 0 }' "$source")
        [[ $count -eq 1 ]] || { echo "Expected exactly one '$key' line; found $count." >&2; exit 1; }
        backup="$config_root/change-backups/$(date +%Y%m%d-%H%M%S)-$(basename "$source")"
        mkdir -p "$(dirname "$backup")"
        cp -a -- "$source" "$backup"
        KEY="$key" VALUE="$value" perl -i -pe '
            if (/^(\s*)\Q$ENV{KEY}\E\s*=.*?(\r?\n)$/) {
                $_ = "$1$ENV{KEY} = $ENV{VALUE}$2";
            }
        ' "$source"
        stored=$(KEY="$key" perl -ne 'if (/^\s*\Q$ENV{KEY}\E\s*=\s*(.*?)\s*\r?$/) { print $1; exit }' "$source")
        if [[ $stored != "$value" ]]; then
            cp -a -- "$backup" "$source"
            echo 'Config verification failed; backup restored.' >&2
            exit 1
        fi
        echo "Updated: $source"
        echo "Backup: $backup"
        printf '%s = %s\n' "$key" "$value"
        ;;
    *) usage >&2; exit 2 ;;
esac
