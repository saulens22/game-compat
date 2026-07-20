#!/usr/bin/env bash
set -euo pipefail
case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
command -v gst-inspect-1.0 >/dev/null || { echo 'GStreamer tools are missing.' >&2; exit 1; }
command -v mpv >/dev/null || { echo "mpv is missing. Run $case_dir/../../install-system-packages.sh gta3" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg is missing. Run $case_dir/../../install-system-packages.sh gta3" >&2; exit 1; }
gst-inspect-1.0 mpeg2dec >/dev/null || {
  echo 'MPEG-1/2 decoder missing. On Arch install gst-plugins-ugly.' >&2; exit 1;
}
gst-inspect-1.0 mpg123audiodec >/dev/null || {
  echo 'MPEG audio decoder missing. On Arch install gst-plugins-good.' >&2; exit 1;
}
dummy="$case_dir/runtime/intro-completion.mpg"
if [[ ! -s $dummy ]]; then
  mkdir -p "$(dirname -- "$dummy")"
  ffmpeg -nostdin -v error -f lavfi -i color=c=black:s=16x16:r=30 \
    -f lavfi -i anullsrc=r=44100:cl=stereo -t 0.04 -shortest \
    -c:v mpeg1video -c:a mp2 -b:a 64k -y "$dummy"
fi
[[ -s $dummy ]] || { echo "Failed to create completion clip: $dummy" >&2; exit 1; }
echo 'PASS: native MPEG playback and Proton completion-clip codecs are available.'
echo 'Native quartz remains disabled because its override exits GTA III before a window is created.'
