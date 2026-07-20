#!/usr/bin/env bash
set -euo pipefail

case_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$case_dir/../.." && pwd)
# shellcheck source=../../lib/steam-paths.sh
source "$repo_root/lib/steam-paths.sh"

yes=0
[[ ${1:-} == --yes ]] && { yes=1; shift; }
[[ $# -eq 0 ]] || { echo 'Usage: repair-receipt-save.sh [--yes]' >&2; exit 2; }

if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null || pgrep -f '[M]urdered\.exe' >/dev/null; then
    echo 'Exit Murdered: Soul Suspect and Steam before repairing the save.' >&2
    echo 'This script never stops them automatically.' >&2
    exit 1
fi

steam_root=$(resolve_steam_root)
localconfig=$(steam_localconfig "$steam_root")
userdata_dir=$(cd -- "$(dirname -- "$localconfig")/.." && pwd)
cloud_dir="$userdata_dir/233290"
save="$cloud_dir/remote/SaveData/FateCheckpoint0/FATEGAME.SAV"
profile="$cloud_dir/remote/profile.bin"
metadata="$cloud_dir/remotecache.vdf"
for required in "$save" "$profile" "$metadata"; do
    [[ -f $required ]] || { echo "Required save component is missing: $required" >&2; exit 1; }
done

state=$(SAVE=$save perl -0777 -ne '
    $tail = "None\0" . ("\0" x 6);
    $complete = "\0\0\0\0\x01\x01\x05\0\0\0" . $tail . "\x03\0\0\0";
    $empty = "\0\0\0\0\0\0\x05\0\0\0" . $tail . "\0\0\0\0";
    $partial = "\0\0\0\0\x01\x01\x05\0\0\0" . $tail . "\0\0\0\0";
    $reset_flags = "\0\0\0\0\0\0\x05\0\0\0" . $tail . "\x03\0\0\0";
    for $id (qw(sq_carnage_crash sq_carnage_scotch)) {
        $marker = "$id\0";
        $count = () = /\Q$marker\E/g;
        die "$id marker count is $count, expected 1\n" unless $count == 1;
        $pos = index($_, $marker) + length($marker);
        $bytes = substr($_, $pos, length($complete));
        die "refusing repair: prerequisite $id is not fully complete with three badges\n"
            unless $bytes eq $complete;
    }
    for $id (qw(sq_carnage_plate sq_carnage_receipt)) {
        $marker = "$id\0";
        $count = () = /\Q$marker\E/g;
        die "$id marker count is $count, expected 1\n" unless $count == 1;
        $pos = index($_, $marker) + length($marker);
        $bytes = substr($_, $pos, length($complete));
        die "unexpected $id record bytes: " . unpack("H*", $bytes) . "\n"
            unless $bytes eq $complete || $bytes eq $empty || $bytes eq $partial || $bytes eq $reset_flags;
    }
    print "supported\n";
' "$save")

echo 'This will mark the SOC receipt complete and reset B-RAD to uncollected.'
echo 'Collect B-RAD again in game so the game itself processes the 3/4 to 4/4 transition.'
echo 'The checkpoint, profile, and Steam Cloud metadata will be backed up together.'
((yes)) || {
    read -r -p 'Apply the guarded receipt repair? [y/N] ' answer
    [[ $answer == [yY] ]] || { echo 'Cancelled.'; exit 1; }
}

stamp=$(date +%Y%m%d-%H%M%S-%N)
backup_dir="$case_dir/runtime/backups/receipt-repair/$stamp"
mkdir -p "$backup_dir"
cp -a -- "$save" "$backup_dir/FATEGAME.SAV"
cp -a -- "$profile" "$backup_dir/profile.bin"
cp -a -- "$metadata" "$backup_dir/remotecache.vdf"
printf '%s\n' "$backup_dir" > "$case_dir/runtime/latest-receipt-repair-backup"

tmp=$(mktemp "${save}.repair.XXXXXX")
cleanup() { [[ ! -e $tmp ]] || rm -f -- "$tmp"; }
trap cleanup EXIT
cp -a -- "$save" "$tmp"
SAVE=$tmp perl -0777 -i -pe '
    $tail = "None\0" . ("\0" x 6);
    $complete = "\0\0\0\0\x01\x01\x05\0\0\0" . $tail . "\x03\0\0\0";
    $empty = "\0\0\0\0\0\0\x05\0\0\0" . $tail . "\0\0\0\0";
    $partial = "\0\0\0\0\x01\x01\x05\0\0\0" . $tail . "\0\0\0\0";
    $reset_flags = "\0\0\0\0\0\0\x05\0\0\0" . $tail . "\x03\0\0\0";
    sub set_record {
        my ($id, $to) = @_;
        my $marker = "$id\0";
        my $count = 0;
        for my $from ($complete, $empty, $partial, $reset_flags) {
            $count += s/\Q$marker$from\E/$marker$to/g;
        }
        die "refusing repair: $id matched $count records instead of 1\n" unless $count == 1;
    }
    set_record("sq_carnage_receipt", $complete);
    set_record("sq_carnage_plate", $empty);
' "$tmp"

changed=$(cmp -l "$save" "$tmp" | wc -l)
[[ $changed -eq 2 || $changed -eq 4 || $changed -eq 6 ]] || {
    echo "Refusing repair: expected a two-, four-, or six-byte delta, found $changed." >&2
    exit 1
}
mv -f -- "$tmp" "$save"
touch -- "$save"
sync "$save"
printf 'v4\n' > "$case_dir/runtime/installed-version"

"$case_dir/verify-receipt-save.sh"
echo "Backup: $backup_dir"
echo 'Repair applied. Start Steam, allow Cloud synchronization, then collect B-RAD again manually.'
