#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  capture-window.sh --id WINDOW_ID OUTPUT.png
  capture-window.sh --name TITLE_REGEX OUTPUT.png
  capture-window.sh --class CLASS_REGEX OUTPUT.png

Captures one KWin window directly and writes metadata beside it as
OUTPUT.png.window.txt. If multiple windows match, the newest match is used.
EOF
}

[[ $# -eq 3 ]] || { usage >&2; exit 2; }
mode=$1
query=$2
output=$3

backend=xwayland
if [[ "${XDG_SESSION_TYPE:-}" == wayland ]] && command -v kdotool >/dev/null; then
  backend=kwin
fi

if [[ "$backend" == kwin ]]; then
  case "$mode" in
    --id) window_id=$query ;;
    --name) window_id=$(kdotool search --name "$query" getwindowid 2>/dev/null | tail -n 1 || true) ;;
    --class) window_id=$(kdotool search --class "$query" getwindowid 2>/dev/null | tail -n 1 || true) ;;
    *) usage >&2; exit 2 ;;
  esac
else
  case "$mode" in
    --id) window_id=$query ;;
    --name) window_id=$(xdotool search --name "$query" 2>/dev/null | tail -n 1 || true) ;;
    --class) window_id=$(xdotool search --class "$query" 2>/dev/null | tail -n 1 || true) ;;
    *) usage >&2; exit 2 ;;
  esac
fi

[[ -n "${window_id:-}" ]] || { echo "No matching window found." >&2; exit 1; }
command -v import >/dev/null || {
  echo "ImageMagick's 'import' command is required for targeted capture." >&2
  exit 1
}

# xdotool returns decimal IDs, while ImageMagick reliably accepts X11 window
# resource IDs in hexadecimal form (especially for large IDs).
if [[ "$backend" == xwayland && "$window_id" =~ ^[0-9]+$ ]]; then
  printf -v capture_id '0x%x' "$window_id"
else
  capture_id=$window_id
fi

mkdir -p "$(dirname "$output")"
if [[ "$backend" == kwin ]] || ! import -window "$capture_id" "$output" 2>/dev/null; then
  command -v spectacle >/dev/null || {
    echo "Direct capture failed and Spectacle is unavailable." >&2
    exit 1
  }
  # Composited fullscreen/hidden Wine windows may not expose readable X11
  # pixels. Activate the requested window, then ask KWin for that window only.
  if [[ "$backend" == kwin ]]; then
    kdotool windowactivate "$window_id"
  else
    xdotool windowactivate --sync "$window_id"
  fi
  spectacle -b -n -a -o "$output"
fi
{
  date -Is
  echo "backend=$backend"
  echo "window_id=$window_id"
  echo "capture_id=$capture_id"
  if [[ "$backend" == kwin ]]; then
    kdotool getwindowname "$window_id" 2>/dev/null || true
    kdotool getwindowclassname "$window_id" 2>/dev/null || true
    kdotool getwindowpid "$window_id" 2>/dev/null || true
    kdotool getwindowgeometry "$window_id" 2>/dev/null || true
    kdotool get_desktop_for_window "$window_id" 2>/dev/null || true
  else
    xdotool getwindowname "$window_id" 2>/dev/null || true
    xprop -id "$window_id" WM_CLASS WM_NAME _NET_WM_NAME _NET_WM_STATE _NET_WM_DESKTOP 2>/dev/null || true
  fi
} > "$output.window.txt"

echo "$output"
echo "$output.window.txt"
