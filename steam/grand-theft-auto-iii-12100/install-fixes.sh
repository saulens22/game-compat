#!/usr/bin/env bash
set -euo pipefail

game_dir=${GTA3_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto 3"}
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
downloads="$case_dir/tool-downloads"
backup="$case_dir/configs/mod-baseline"
widescreen_zip="$downloads/GTA3.WidescreenFix.zip"
silentpatch_zip="$downloads/SilentPatchIII.zip"
ginput_zip="$downloads/GInputIII.zip"

declare -A expected=(
  ["$widescreen_zip"]="38bdeb3b901a4953f1f635685fbd91342dcd3ba4c5a70c621b37ab6f017889e1"
  ["$silentpatch_zip"]="7f57fb59707649e29168b025c0297be282a4ba7d8dc5109b7536e783a363d949"
  ["$ginput_zip"]="0278f4115f788b878fcb83b9cc8912df4c6f1bba174f5c34b4ed7dc8c896f7c2"
)
declare -A url=(
  ["$widescreen_zip"]="https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/gta3/GTA3.WidescreenFix.zip"
  ["$silentpatch_zip"]="https://github.com/CookiePLMonster/SilentPatch/releases/download/1.1-BUILD9.2-III/SilentPatchIII.zip"
  ["$ginput_zip"]="https://silent.rockstarvision.com/uploads/GInputIII.zip"
)

[[ -f "$game_dir/gta3.exe" ]] || { echo "GTA III not found: $game_dir" >&2; exit 1; }
if pgrep -f '[g]ta3.exe|[r]e3' >/dev/null; then
  echo 'Refusing to install while GTA III is running.' >&2
  exit 1
fi
mkdir -p "$downloads" "$backup/files"

for archive in "$widescreen_zip" "$silentpatch_zip" "$ginput_zip"; do
  [[ -f $archive ]] || curl --fail --location --output "$archive" "${url[$archive]}"
  printf '%s  %s\n' "${expected[$archive]}" "$archive" | sha256sum --check --status || {
    echo "Checksum mismatch: $archive" >&2; exit 1;
  }
  unzip -tq "$archive" >/dev/null
done

targets=(
  d3d8.dll
  scripts/global.ini
  scripts/GTA3.WidescreenFix.asi
  scripts/GTA3.WidescreenFix.ini
  scripts/SilentPatchIII.asi
  scripts/SilentPatchIII.ini
  scripts/GInputIII.asi
  scripts/GInputIII.ini
  models/x360btns.txd
  models/ps3btns.txd
  models/sixaxis.txd
)

if [[ ! -f "$backup/manifest.tsv" ]]; then
  printf 'relative_path\toriginal_state\tsha256\n' > "$backup/manifest.tsv"
  for rel in "${targets[@]}"; do
    if [[ -f "$game_dir/$rel" ]]; then
      mkdir -p "$backup/files/$(dirname -- "$rel")"
      cp -a -- "$game_dir/$rel" "$backup/files/$rel"
      printf '%s\tpresent\t%s\n' "$rel" "$(sha256sum "$game_dir/$rel" | cut -d' ' -f1)" >> "$backup/manifest.tsv"
    else
      printf '%s\tabsent\t-\n' "$rel" >> "$backup/manifest.tsv"
    fi
  done
fi

# Older revisions of this setup placed SilentPatch in the game root even
# though this loader is configured with LoadFromScriptsOnly=1. Extend an
# existing baseline manifest for the corrected destinations without replacing
# its original rollback data.
for rel in scripts/SilentPatchIII.asi scripts/SilentPatchIII.ini scripts/GInputIII.asi scripts/GInputIII.ini models/x360btns.txd models/ps3btns.txd models/sixaxis.txd; do
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

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
unzip -q "$widescreen_zip" -d "$tmp/widescreen"
unzip -q "$silentpatch_zip" -d "$tmp/silentpatch"
unzip -q "$ginput_zip" -d "$tmp/ginput"
sed -i -E 's/^ResX[[:space:]]*=.*/ResX = 0/; s/^ResY[[:space:]]*=.*/ResY = 0/' \
  "$tmp/widescreen/scripts/GTA3.WidescreenFix.ini"
sed -i -E 's/^ControlsSet=.*/ControlsSet=5/; s/^PlayStationButtons=.*/PlayStationButtons=0/; s/^LeftStickSensitivity=.*/LeftStickSensitivity=75/; s/^RightStickSensitivity=.*/RightStickSensitivity=75/' \
  "$tmp/ginput/GInputIII.ini"
mkdir -p "$game_dir/scripts"
install -m 0644 "$tmp/widescreen/d3d8.dll" "$game_dir/d3d8.dll"
install -m 0644 "$tmp/widescreen/scripts/global.ini" "$game_dir/scripts/global.ini"
install -m 0644 "$tmp/widescreen/scripts/GTA3.WidescreenFix.asi" "$game_dir/scripts/GTA3.WidescreenFix.asi"
install -m 0644 "$tmp/widescreen/scripts/GTA3.WidescreenFix.ini" "$game_dir/scripts/GTA3.WidescreenFix.ini"
install -m 0644 "$tmp/silentpatch/SilentPatchIII.asi" "$game_dir/scripts/SilentPatchIII.asi"
install -m 0644 "$tmp/silentpatch/SilentPatchIII.ini" "$game_dir/scripts/SilentPatchIII.ini"
install -m 0644 "$tmp/ginput/GInputIII.asi" "$game_dir/scripts/GInputIII.asi"
install -m 0644 "$tmp/ginput/GInputIII.ini" "$game_dir/scripts/GInputIII.ini"
install -m 0644 "$tmp/ginput/models/x360btns.txd" "$game_dir/models/x360btns.txd"
install -m 0644 "$tmp/ginput/models/ps3btns.txd" "$game_dir/models/ps3btns.txd"
install -m 0644 "$tmp/ginput/models/sixaxis.txd" "$game_dir/models/sixaxis.txd"
rm -f "$game_dir/SilentPatchIII.asi" "$game_dir/SilentPatchIII.ini"

for rel in "${targets[@]}"; do [[ -s "$game_dir/$rel" ]] || { echo "Install verification failed: $rel" >&2; exit 1; }; done
grep -qx 'ResX = 0' "$game_dir/scripts/GTA3.WidescreenFix.ini"
grep -qx 'ResY = 0' "$game_dir/scripts/GTA3.WidescreenFix.ini"
grep -qx 'ControlsSet=5' "$game_dir/scripts/GInputIII.ini"
grep -qx 'PlayStationButtons=0' "$game_dir/scripts/GInputIII.ini"
grep -qx 'LeftStickSensitivity=75' "$game_dir/scripts/GInputIII.ini"
grep -qx 'RightStickSensitivity=75' "$game_dir/scripts/GInputIII.ini"
echo 'Installed and verified SilentPatch III 9.2, Widescreen Fix, and GInput III 1.11 with GTA IV-style controls.'
echo "Rollback: $case_dir/rollback-fixes.sh"
