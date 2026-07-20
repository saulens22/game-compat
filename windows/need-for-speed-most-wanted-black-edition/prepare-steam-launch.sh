#!/usr/bin/env bash
set -euo pipefail

# 0xffffffff tells the current Widescreen Fix to select the active desktop.
# The game writes a concrete resolution back on exit, so reset this before each
# direct Steam launch to remain portable across monitor changes.
flatpak run --command=bottles-cli com.usebottles.bottles reg edit \
    -b nfsmw-black-edition \
    -k 'HKEY_CURRENT_USER\Software\EA Games\Need for Speed Most Wanted' \
    -v g_RacingResolution -d 4294967295 -t REG_DWORD
