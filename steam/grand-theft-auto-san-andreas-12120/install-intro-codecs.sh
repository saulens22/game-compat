#!/usr/bin/env bash
set -euo pipefail
command -v gst-inspect-1.0 >/dev/null || { echo 'GStreamer tools are missing.' >&2; exit 1; }
gst-inspect-1.0 mpeg2dec >/dev/null || {
  echo 'MPEG-1/2 decoder missing. On Arch install gst-plugins-ugly.' >&2; exit 1;
}
gst-inspect-1.0 mpg123audiodec >/dev/null || {
  echo 'MPEG audio decoder missing. On Arch install gst-plugins-good.' >&2; exit 1;
}
echo 'PASS: host MPEG video/audio codecs used by Proton winegstreamer are available.'
echo 'No native quartz or prefix codec override is installed; those regressed startup in testing.'
