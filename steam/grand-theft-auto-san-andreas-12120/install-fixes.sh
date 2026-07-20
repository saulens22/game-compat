#!/usr/bin/env bash
set -euo pipefail

game_dir=${GTASA_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto San Andreas"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
downloads="$case_dir/tool-downloads"; backup="$case_dir/configs/mod-baseline"
ws="$downloads/GTASA.WidescreenFix.zip"; sp="$downloads/SilentPatchSA.zip"
declare -A sums=(
  ["$ws"]="38d648c33d43b3459f3b8e2ab2ee5086fbd84f2567c9d9b4d191a2239f68810e"
  ["$sp"]="5d915e9f3bbab7137e1fb9d1c3f731e895a88a500557649291f9694c007ef611"
)
declare -A urls=(
  ["$ws"]="https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/gtasa/GTASA.WidescreenFix.zip"
  ["$sp"]="https://github.com/CookiePLMonster/SilentPatch/releases/download/1.1-BUILD9.2-III/SilentPatchSA.zip"
)
[[ -f "$game_dir/gta-sa.exe" ]] || { echo "San Andreas not found: $game_dir" >&2; exit 1; }
pgrep -f '[g]ta-sa.exe' >/dev/null && { echo 'Refusing while San Andreas is running.' >&2; exit 1; }
mkdir -p "$downloads" "$backup/files"
for archive in "$ws" "$sp"; do
  [[ -f $archive ]] || curl -fL -o "$archive" "${urls[$archive]}"
  printf '%s  %s\n' "${sums[$archive]}" "$archive" | sha256sum -c --status
  unzip -tq "$archive" >/dev/null
done
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
unzip -q "$ws" -d "$tmp/payload"; unzip -q "$sp" -d "$tmp/payload"; rm -f "$tmp/payload/ReadMe.txt"
# The installed 5,971,456-byte NewSteam executable is not supported by the
# ThirteenAG widescreen ASI. Keep the packaged vorbisFile ASI loader for
# SilentPatch, but do not install the incompatible plugin or its INI.
rm -f "$tmp/payload/scripts/GTASA.WidescreenFix.asi" "$tmp/payload/scripts/GTASA.WidescreenFix.ini"
# Preserve the complete startup sequence. SilentPatch defaults to skipping the
# intro splashes, but this setup deliberately leaves them enabled.
sed -i -E 's/^SkipIntroSplashes=.*/SkipIntroSplashes=0/' "$tmp/payload/SilentPatchSA.ini"
mapfile -t targets < <(cd "$tmp/payload" && find . -type f -printf '%P\n' | LC_ALL=C sort)
if [[ ! -f "$backup/manifest.tsv" ]]; then
  printf 'relative_path\toriginal_state\tsha256\n' > "$backup/manifest.tsv"
  for rel in "${targets[@]}"; do
    if [[ -f "$game_dir/$rel" ]]; then
      mkdir -p "$backup/files/$(dirname -- "$rel")"; cp -a "$game_dir/$rel" "$backup/files/$rel"
      printf '%s\tpresent\t%s\n' "$rel" "$(sha256sum "$game_dir/$rel" | cut -d' ' -f1)" >> "$backup/manifest.tsv"
    else printf '%s\tabsent\t-\n' "$rel" >> "$backup/manifest.tsv"; fi
  done
fi
while IFS= read -r -d '' src; do rel=${src#"$tmp/payload/"}; install -D -m 0644 "$src" "$game_dir/$rel"; done < <(find "$tmp/payload" -type f -print0)
rm -f "$game_dir/scripts/GTASA.WidescreenFix.asi" "$game_dir/scripts/GTASA.WidescreenFix.ini"
for rel in "${targets[@]}"; do cmp -s "$tmp/payload/$rel" "$game_dir/$rel" || { echo "Verification failed: $rel" >&2; exit 1; }; done
grep -Eq '^SkipIntroSplashes=0[[:space:]]*$' "$game_dir/SilentPatchSA.ini"
echo 'Installed and verified SilentPatch SA 33.1 with an ASI loader and full startup splashes for the NewSteam executable.'
