#!/usr/bin/env bash
set -euo pipefail
game_dir=${GTAVC_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto Vice City"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backup="$case_dir/configs/mod-baseline"; manifest="$backup/manifest.tsv"
[[ -f $manifest ]] || { echo "No baseline manifest: $manifest" >&2; exit 1; }
pgrep -f '[g]ta-vc.exe' >/dev/null && { echo 'Refusing while Vice City is running.' >&2; exit 1; }
tail -n +2 "$manifest" | while IFS=$'\t' read -r rel state digest; do
  if [[ $state == present ]]; then
    install -D -m 0644 "$backup/files/$rel" "$game_dir/$rel"
    printf '%s  %s\n' "$digest" "$game_dir/$rel" | sha256sum -c --status
  elif [[ $state == absent ]]; then rm -f "$game_dir/$rel"; else echo "Bad state: $state" >&2; exit 1; fi
done
find "$game_dir/scripts" -depth -type d -empty -delete 2>/dev/null || true
echo 'Restored the pre-mod Vice City file state.'
