#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"
steam_root=$(resolve_steam_root)
localconfig=$(steam_localconfig "$steam_root")
userdata_dir=$(cd -- "$(dirname -- "$localconfig")/.." && pwd)
save="$userdata_dir/233290/remote/SaveData/FateCheckpoint0/FATEGAME.SAV"
[[ -f $save ]] || { echo "FAIL: missing $save" >&2; exit 1; }

SAVE=$save perl -0777 -ne '
    $tail = "None\0" . ("\0" x 6);
    $complete = "\0\0\0\0\x01\x01\x05\0\0\0" . $tail . "\x03\0\0\0";
    $empty = "\0\0\0\0\0\0\x05\0\0\0" . $tail . "\0\0\0\0";
    for $id (qw(sq_carnage_crash sq_carnage_scotch)) {
        $prerequisite = "$id\0";
        $count = () = /\Q$prerequisite\E/g;
        die "FAIL: $id marker count is $count, expected 1\n" unless $count == 1;
        $pos = index($_, $prerequisite) + length($prerequisite);
        $bytes = substr($_, $pos, length($complete));
        die "FAIL: prerequisite $id is not complete with three badges\n"
            unless $bytes eq $complete;
    }
    $brad = "sq_carnage_plate\0";
    $count = () = /\Q$brad\E/g;
    die "FAIL: B-RAD marker count is $count, expected 1\n" unless $count == 1;
    $pos = index($_, $brad) + length($brad);
    $bytes = substr($_, $pos, length($empty));
    die "FAIL: B-RAD is not fully reset with zero badges\n" unless $bytes eq $empty;
    $marker = "sq_carnage_receipt\0";
    $count = () = /\Q$marker\E/g;
    die "FAIL: receipt marker count is $count, expected 1\n" unless $count == 1;
    $pos = index($_, $marker) + length($marker);
    $bytes = substr($_, $pos, length($complete));
    die "FAIL: receipt is not complete with three badges\n" unless $bytes eq $complete;
    print "PASS: receipt is complete with three badges; B-RAD is fully reset with zero badges.\n";
' "$save"
