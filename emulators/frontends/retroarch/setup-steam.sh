#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../../.." && pwd)
systems_file="$repo_root/emulators/systems.txt"
# shellcheck source=../../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
library=$EMULATION_ROOT

if pgrep -x retroarch >/dev/null || pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo 'Exit RetroArch and Steam before applying this setup.' >&2
    exit 1
fi

config=${RETROARCH_CONFIG:-}
if [[ -z $config ]]; then
    config=$(steam_app_install_dir "$(resolve_steam_root)" 1118310)/retroarch.cfg
fi
[[ -f $config ]] || { echo 'RetroArch Steam config was not found. Run App ID 1118310 once first.' >&2; exit 1; }

mkdir -p "$library"/{bios,cores,core-info,metadata,playlists,saves,states,screenshots,configs,backups/config,roms}
while read -r system _; do
    [[ -n $system && $system != \#* ]] || continue
    mkdir -p "$library/roms/$system"
done < "$systems_file"
localconfig=$(steam_localconfig "$(resolve_steam_root)")
previous=$(APP_ID=1118310 perl -ne '
    if (!$in && /^\s*"\Q$ENV{APP_ID}\E"\s*$/) { $in=1; $await=1 }
    if ($in && /^\s*"LaunchOptions"\s+"((?:[^"\\]|\\.)*)"/) { $v=$1; $v =~ s/\\"/"/g; $v =~ s/\\\\/\\/g; print $v; exit }
    if ($in && $await && /\{/) { $depth=1; $await=0 }
    elsif ($in && !$await) { $depth += tr/{/{/; $depth -= tr/}/}/; $in=0 if $depth == 0 }
' "$localconfig")
printf '%s' "$previous" > "$library/metadata/previous-launch-options"
timestamp=$(date +%Y%m%d-%H%M%S)
backup="$library/backups/config/retroarch.cfg.$timestamp"
cp -a -- "$config" "$backup"
printf '%s\n' "$backup" > "$library/metadata/last-config-backup"

CONFIG=$config LIBRARY=$library perl -i -pe '
    BEGIN { %v = (
      libretro_directory => "$ENV{LIBRARY}/cores",
      libretro_info_path => "$ENV{LIBRARY}/core-info",
      system_directory => "$ENV{LIBRARY}/bios",
      savefile_directory => "$ENV{LIBRARY}/saves",
      savestate_directory => "$ENV{LIBRARY}/states",
      playlist_directory => "$ENV{LIBRARY}/playlists",
      screenshot_directory => "$ENV{LIBRARY}/screenshots",
      rgui_config_directory => "$ENV{LIBRARY}/configs",
      input_remapping_directory => "$ENV{LIBRARY}/configs/remaps",
      rgui_browser_directory => "$ENV{LIBRARY}/roms"
    ) }
    if (/^([a-z0-9_]+) = / && exists $v{$1}) { $_ = qq{$1 = "$v{$1}"\n} }
' "$config"

# Steam's SDL virtual Xbox pad: Menu opens RetroArch, while the triggers provide
# direct hold-to-fast-forward and rewind. The left stick also drives the D-pad.
CONFIG=$config perl -i -pe '
    BEGIN { %v = (
      input_enable_hotkey_btn => "nul",
      audio_fastforward_mute => "false",
      audio_fastforward_speedup => "false",
      fastforward_ratio => "4.000000",
      fastforward_ratio_throttle_enable => "true",
      input_hold_fast_forward_axis => "+5",
      input_rewind_axis => "+4",
      input_menu_toggle_btn => "6",
      input_menu_toggle_gamepad_combo => "0",
      input_player1_analog_dpad_mode => "1",
      rewind_enable => "true"
    ) }
    if (/^([a-z0-9_]+) = / && exists $v{$1}) { $_ = qq{$1 = "$v{$1}"\n} }
' "$config"

EMULATION_ROOT=$library "$case_dir/update-cores.sh"
EMULATION_ROOT=$library "$case_dir/install-mgba-xbox-label-remap.sh"
"$repo_root/set-steam-launch-options.sh" 1118310 "PRESSURE_VESSEL_FILESYSTEMS_RW=\"$library\" %command%"

echo "Configured RetroArch library: $library"
echo "Config backup: $backup"
echo 'Restart Steam, launch RetroArch, then use Import Content on the roms directory.'
