#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
game_dir=${GTA3_DIR:-"$HOME/.local/share/Steam/steamapps/common/Grand Theft Auto 3"}
dummy="$case_dir/runtime/intro-completion.mpg"
input_conf="$case_dir/mpv-intro-input.conf"
controller_skip="$case_dir/runtime/controller-skip"
log="$case_dir/logs/intro-wrapper.log"
lock="$case_dir/runtime/intro-wrapper.lock"
mpv_socket="$case_dir/runtime/mpv-intro.sock"
mpv_debug_log="$case_dir/logs/mpv-intro-debug.log"
movies=("$game_dir/movies/Logo.mpg" "$game_dir/movies/GTAtitles.mpg")

[[ $# -gt 0 ]] || { echo 'The Proton game command is missing.' >&2; exit 2; }
command -v mpv >/dev/null || { echo "mpv is required. Run $case_dir/../../install-system-packages.sh gta3" >&2; exit 1; }
[[ -s $dummy ]] || { echo "Missing completion clip: $dummy" >&2; exit 1; }
[[ -s $input_conf ]] || { echo "Missing mpv input bindings: $input_conf" >&2; exit 1; }
[[ -x $controller_skip ]] || { echo "Missing controller bridge; run $case_dir/build-controller-skip.sh" >&2; exit 1; }
for movie in "${movies[@]}"; do
  [[ -s $movie ]] || { echo "Missing original intro: $movie" >&2; exit 1; }
done

mkdir -p "$case_dir/logs" "$case_dir/runtime"
exec 9>"$lock"
flock -n 9 || { echo 'Another GTA III intro wrapper is active.' >&2; exit 1; }

restore_movies() {
  local movie backup
  for movie in "${movies[@]}"; do
    backup="$movie.gta3-intro-original"
    if [[ -e $backup ]]; then
      rm -f -- "$movie"
      mv -- "$backup" "$movie"
    fi
  done
}
trap restore_movies EXIT INT TERM

# Recover originals if a previous launch was forcibly interrupted.
restore_movies
printf '%s host playback start\n' "$(date -Is)" >> "$log"
rm -f -- "$mpv_socket"
# Steam exports its Overlay LD_PRELOAD to every child. These host-only helper
# processes must not load it; the Proton command below still inherits it.
env -u LD_PRELOAD mpv --fs --no-border --no-terminal --really-quiet --keep-open=no --no-osc \
  --osd-level=0 --cursor-autohide=always --input-gamepad=yes \
  --input-ipc-server="$mpv_socket" --log-file="$mpv_debug_log" --msg-level=input=trace \
  --input-conf="$input_conf" --audio-client-name='GTA III Intro' -- "${movies[@]}" &
mpv_pid=$!
joysticks=(/dev/input/js* /dev/input/event*)
controller_pid=
if [[ -e ${joysticks[0]} ]]; then
  printf '%s controller bridge start: %s\n' "$(date -Is)" "${joysticks[*]}" >> "$log"
  env -u LD_PRELOAD "$controller_skip" "$mpv_pid" "$mpv_socket" "${joysticks[@]}" 2>> "$log" &
  controller_pid=$!
fi
set +e
wait "$mpv_pid"
mpv_status=$?
set -e
if [[ -n $controller_pid ]]; then
  kill "$controller_pid" 2>/dev/null || true
  set +e
  wait "$controller_pid" 2>/dev/null
  controller_status=$?
  set -e
  printf '%s controller bridge exit=%s; mpv exit=%s\n' \
    "$(date -Is)" "$controller_status" "$mpv_status" >> "$log"
fi
# SIGTERM from the controller bridge is an intentional skip (128 + 15).
[[ $mpv_status -eq 0 || $mpv_status -eq 143 ]] || exit "$mpv_status"
printf '%s host playback complete; starting Proton\n' "$(date -Is)" >> "$log"

# Wine's Quartz graph manager advances correctly on these short clips, but its
# video presenter is a stub. The player already showed the original clips, so
# use a silent completion clip only while GTA executes its two DirectShow calls.
for movie in "${movies[@]}"; do
  mv -- "$movie" "$movie.gta3-intro-original"
  install -m 0644 "$dummy" "$movie"
done

"$@" &
game_launcher_pid=$!
(
  for _ in $(seq 1 60); do
    pgrep -f 'S:\\common\\Grand Theft Auto 3\\gta3.exe' >/dev/null && break
    sleep 0.5
  done
  sleep 5
  restore_movies
  printf '%s original movie files restored\n' "$(date -Is)" >> "$log"
) &
restore_pid=$!

set +e
wait "$game_launcher_pid"
status=$?
set -e
restore_movies
wait "$restore_pid" 2>/dev/null || true
exit "$status"
