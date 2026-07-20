#!/usr/bin/env bash
set -euo pipefail

game_dir=${GTA3_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto 3"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backup="$case_dir/configs/mod-baseline"
manifest="$backup/manifest.tsv"

[[ -f $manifest ]] || { echo "No baseline manifest: $manifest" >&2; exit 1; }
if pgrep -f '[g]ta3.exe|[r]e3' >/dev/null; then
  echo 'Refusing to roll back while GTA III is running.' >&2
  exit 1
fi

tail -n +2 "$manifest" | while IFS=$'\t' read -r rel state digest; do
  case $state in
    present)
      [[ -f "$backup/files/$rel" ]] || { echo "Missing baseline copy: $rel" >&2; exit 1; }
      install -D -m 0644 "$backup/files/$rel" "$game_dir/$rel"
      printf '%s  %s\n' "$digest" "$game_dir/$rel" | sha256sum --check --status
      ;;
    absent) rm -f -- "$game_dir/$rel" ;;
    *) echo "Invalid baseline state for $rel: $state" >&2; exit 1 ;;
  esac
done
rmdir --ignore-fail-on-non-empty "$game_dir/scripts" 2>/dev/null || true
echo 'Restored the pre-mod GTA III file state.'
