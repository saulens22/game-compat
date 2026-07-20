#!/usr/bin/env bash
set -euo pipefail

game_dir=${GTAVC_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto Vice City"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
downloads="$case_dir/tool-downloads"
backup="$case_dir/configs/mod-baseline"
ws="$downloads/GTAVC.WidescreenFix.zip"
sp="$downloads/SilentPatchVC.zip"

declare -A sums=(
  ["$ws"]="2a8c8b46f6b50bfaea063d3be4c2c13acac0066385ffec4d51bfe5812af0f5e3"
  ["$sp"]="1cd0bf2c6b5e186f4fd397cafc41bbd3ca2e9c8fc04333f6f73a14b7258d2b3d"
)
declare -A urls=(
  ["$ws"]="https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/gtavc/GTAVC.WidescreenFix.zip"
  ["$sp"]="https://github.com/CookiePLMonster/SilentPatch/releases/download/1.1-BUILD9.2-III/SilentPatchVC.zip"
)

[[ -f "$game_dir/gta-vc.exe" ]] || { echo "Vice City not found: $game_dir" >&2; exit 1; }
pgrep -f '[g]ta-vc.exe' >/dev/null && { echo 'Refusing while Vice City is running.' >&2; exit 1; }
mkdir -p "$downloads" "$backup/files"
for archive in "$ws" "$sp"; do
  [[ -f $archive ]] || curl -fL -o "$archive" "${urls[$archive]}"
  printf '%s  %s\n' "${sums[$archive]}" "$archive" | sha256sum -c --status
  unzip -tq "$archive" >/dev/null
done

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
unzip -q "$ws" -d "$tmp/payload"
unzip -q "$sp" -d "$tmp/payload"
rm -f "$tmp/payload/ReadMe.txt"
mapfile -t targets < <(cd "$tmp/payload" && find . -type f -printf '%P\n' | LC_ALL=C sort)
# This package sets LoadFromScriptsOnly=1, so SilentPatch must live beside the
# Widescreen Fix in scripts/ rather than in the ignored game root.
mkdir -p "$tmp/payload/scripts"
mv "$tmp/payload/SilentPatchVC.asi" "$tmp/payload/scripts/SilentPatchVC.asi"
mv "$tmp/payload/SilentPatchVC.ini" "$tmp/payload/scripts/SilentPatchVC.ini"
mapfile -t targets < <(cd "$tmp/payload" && find . -type f -printf '%P\n' | LC_ALL=C sort)
if [[ ! -f "$backup/manifest.tsv" ]]; then
  printf 'relative_path\toriginal_state\tsha256\n' > "$backup/manifest.tsv"
  for rel in "${targets[@]}"; do
    if [[ -f "$game_dir/$rel" ]]; then
      mkdir -p "$backup/files/$(dirname -- "$rel")"
      cp -a "$game_dir/$rel" "$backup/files/$rel"
      printf '%s\tpresent\t%s\n' "$rel" "$(sha256sum "$game_dir/$rel" | cut -d' ' -f1)" >> "$backup/manifest.tsv"
    else printf '%s\tabsent\t-\n' "$rel" >> "$backup/manifest.tsv"; fi
  done
fi
for rel in scripts/SilentPatchVC.asi scripts/SilentPatchVC.ini; do
  if ! awk -F '\t' -v rel="$rel" 'NR > 1 && $1 == rel { found=1 } END { exit !found }' "$backup/manifest.tsv"; then
    if [[ -f "$game_dir/$rel" ]]; then
      mkdir -p "$backup/files/$(dirname -- "$rel")"
      cp -a -- "$game_dir/$rel" "$backup/files/$rel"
      printf '%s\tpresent\t%s\n' "$rel" "$(sha256sum "$game_dir/$rel" | cut -d' ' -f1)" >> "$backup/manifest.tsv"
    else
      printf '%s\tabsent\t-\n' "$rel" >> "$backup/manifest.tsv"
    fi
  fi
done
while IFS= read -r -d '' src; do rel=${src#"$tmp/payload/"}; install -D -m 0644 "$src" "$game_dir/$rel"; done < <(find "$tmp/payload" -type f -print0)
for rel in "${targets[@]}"; do cmp -s "$tmp/payload/$rel" "$game_dir/$rel" || { echo "Verification failed: $rel" >&2; exit 1; }; done
rm -f "$game_dir/SilentPatchVC.asi" "$game_dir/SilentPatchVC.ini"
echo 'Installed and verified SilentPatch VC 11.1 and the Vice City Widescreen Fix with automatic resolution.'
