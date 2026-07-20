#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  experiment-guard.sh check  GAME_DIR 'CANONICAL SIGNATURE'
  experiment-guard.sh record GAME_DIR 'CANONICAL SIGNATURE' RESULT

The ledger is GAME_DIR/experiments.tsv with this strict schema:
signature_sha256<TAB>timestamp<TAB>canonical_signature<TAB>result
"check" exits 10 when the exact signature was already recorded. Use stable
key=value fields in a consistent order and include every effective test variable.
EOF
}

[[ $# -ge 3 ]] || { usage >&2; exit 2; }
action=$1
game_dir=$(realpath -e -- "$2")
signature=$3
ledger="$game_dir/experiments.tsv"
[[ $signature != *$'\n'* && $signature != *$'\t'* ]] || {
    echo 'Signature must be one line without tabs.' >&2; exit 2;
}
if [[ ! -e $ledger ]]; then
    printf 'signature_sha256\ttimestamp\tcanonical_signature\tresult\n' > "$ledger"
fi
hash=$(printf %s "$signature" | sha256sum | cut -d' ' -f1)

if awk -F '\t' -v hash="$hash" -v sig="$signature" \
    'NR > 1 && $1 == hash && $3 == sig { found=1 } END { exit !found }' "$ledger"; then
    echo "DUPLICATE: $signature" >&2
    awk -F '\t' -v hash="$hash" -v sig="$signature" \
        'NR > 1 && $1 == hash && $3 == sig' "$ledger" >&2
    exit 10
fi

case $action in
    check)
        echo "NEW: $signature"
        ;;
    record)
        [[ $# -eq 4 ]] || { usage >&2; exit 2; }
        result=$4
        [[ $result != *$'\n'* && $result != *$'\t'* ]] || {
            echo 'Result must be one line without tabs.' >&2; exit 2;
        }
        printf '%s\t%s\t%s\t%s\n' "$hash" "$(date --iso-8601=seconds)" \
            "$signature" "$result" >> "$ledger"
        echo "Recorded: $signature"
        ;;
    *) usage >&2; exit 2 ;;
esac
