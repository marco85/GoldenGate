#!/bin/sh
# flash-usb.sh -- Safely write a GoldenGate OS ISO to the 16 GB USB stick on macOS, then verify SHA-256.
#
#   sh tools/flash-usb.sh out/goldengate-....iso   asks which disk, then writes
#   sh tools/flash-usb.sh --check disk5            only checks whether disk5 is safe to write
#
# Strictly refuses internal disks, partitions, any drive >= 64 GB, and any drive
# holding a volume named "SANDISK USB" (the 250 GB project archive drive).
set -eu
LIMIT=64000000000

du_() { if [ -n "${DISKUTIL:-}" ]; then sh "$DISKUTIL" "$@"; else diskutil "$@"; fi; }
refuse() { echo "flash-usb: refusing ${1:-(nothing)}: $2" >&2; exit 3; }

check_disk() {
    d=$1
    case "$d" in
    disk[0-9]*s[0-9]*) refuse "$d" "that is a partition; name the whole disk (e.g. disk5, not disk5s1)" ;;
    disk[0-9]*) ;;
    *) refuse "$d" "not a disk id like disk5" ;;
    esac
    info=$(mktemp)
    du_ info -plist "$d" > "$info" 2>/dev/null || { rm -f "$info"; refuse "$d" "diskutil does not know it"; }
    internal=$(plutil -extract Internal raw "$info" 2>/dev/null || echo true)
    size=$(plutil -extract TotalSize raw "$info" 2>/dev/null || echo 0)
    rm -f "$info"
    [ "$internal" = false ] || refuse "$d" "it is an internal disk"
    [ "$size" -gt 0 ] || refuse "$d" "its size is unknown"
    [ "$size" -lt "$LIMIT" ] || refuse "$d" "it is $((size / 1000000000)) GB; the 16 GB installer stick is smaller (this protects SANDISK USB)"
    if du_ list "$d" | grep -q "SANDISK USB"; then
        refuse "$d" "it holds the SANDISK USB archive volume"
    fi
}

if [ "${1:-}" = --check ]; then
    check_disk "${2:-}"
    echo "flash-usb: ${2} may be written (16 GB USB installer verified)"
    exit 0
fi

if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
    iso=$1
else
    iso=$(ls -t out/*.iso 2>/dev/null | head -n 1 || true)
fi
[ -n "$iso" ] && [ -f "$iso" ] || { echo "flash-usb: no ISO file provided and none found in out/*.iso" >&2; exit 2; }
echo "Using GoldenGate OS ISO: $iso"
du_ list external physical
if [ $# -ge 2 ] && [ -n "${2:-}" ]; then
    d=$2
else
    printf 'Which disk is the 16 GB USB installer stick? (for example disk5): '
    read -r d
fi
check_disk "$d"
if [ "${FORCE:-}" != "1" ]; then
    printf 'Everything on %s will be erased. Type %s again to confirm: ' "$d" "$d"
    read -r again
    [ "$again" = "$d" ] || { echo "flash-usb: confirmation did not match; nothing was written"; exit 1; }
fi
du_ unmountDisk "/dev/$d"
size=$(stat -f %z "$iso")
want=$(shasum -a 256 "$iso" | cut -d' ' -f1)
blocks=$(( (size + 4194303) / 4194304 ))

echo "Writing GoldenGate OS to /dev/r$d (takes ~2-3 minutes; macOS may ask for your password)..."

if sudo -n true 2>/dev/null; then
    sudo dd if="$iso" of="/dev/r$d" bs=4m
    sync
    got=$(sudo dd if="/dev/r$d" bs=4m count="$blocks" 2>/dev/null | head -c "$size" | shasum -a 256 | cut -d' ' -f1)
    [ "$want" = "$got" ] || { echo "flash-usb: SHA-256 verification failed on USB readback! Expected $want, got $got"; exit 4; }
    du_ eject "/dev/$d"
    echo "flash-usb: GoldenGate OS written and SHA-256 verified on 16 GB USB stick. Ready to boot Surface Laptop 5!"
    exit 0
fi

WRITE_ISO="$iso"
case "$iso" in
/tmp/*) ;;
*)
    if [ -f "/tmp/goldengate.iso" ] && [ "$(stat -f %z "/tmp/goldengate.iso" 2>/dev/null)" = "$size" ]; then
        WRITE_ISO="/tmp/goldengate.iso"
    else
        TMP_ISO="/tmp/goldengate-staged.iso"
        if [ ! -f "$TMP_ISO" ] || [ "$(stat -f %z "$TMP_ISO" 2>/dev/null)" != "$size" ]; then
            echo "Staging ISO to $TMP_ISO for macOS administrator disk access..."
            cp "$iso" "$TMP_ISO"
        fi
        WRITE_ISO="$TMP_ISO"
    fi
    ;;
esac

STATUS_FILE=$(mktemp /tmp/goldengate-flash-status.XXXXXX)
rm -f "$STATUS_FILE"

STAGE_SCRIPT=$(mktemp /tmp/goldengate-flash-exec.XXXXXX)
cat > "$STAGE_SCRIPT" << EOF
#!/bin/sh
echo "=== GoldenGate OS — 16 GB USB Installer Writer ==="
echo "Target disk: /dev/r$d (SANDISK USB protected)"
echo "Payload: $WRITE_ISO ($size bytes)"
echo ""
echo "Please enter your administrator password if prompted by sudo:"
sudo dd if="$WRITE_ISO" of="/dev/r$d" bs=4m
sync
echo "Reading back USB sectors to verify SHA-256..."
got=\$(sudo dd if="/dev/r$d" bs=4m count="$blocks" 2>/dev/null | head -c "$size" | shasum -a 256 | cut -d' ' -f1)
echo "Expected SHA-256: $want"
echo "Readback SHA-256: \$got"
if [ "\$got" != "$want" ]; then
    echo "ERROR: SHA-256 mismatch on readback!" >&2
    echo "FAILED" > "$STATUS_FILE"
    exit 4
fi
diskutil eject "/dev/$d"
echo "SUCCESS: GoldenGate OS written and SHA-256 verified on 16 GB USB stick."
echo "SUCCESS" > "$STATUS_FILE"
EOF
chmod 755 "$STAGE_SCRIPT"

cleanup() {
    rm -f "$STAGE_SCRIPT" "$STATUS_FILE"
}
trap cleanup EXIT

if sudo -n true 2>/dev/null; then
    sh "$STAGE_SCRIPT"
else
    echo "Opening Terminal.app for native macOS administrator password entry..."
    osascript -e 'tell application "Terminal" to activate' -e "tell application \"Terminal\" to do script \"sh '$STAGE_SCRIPT'; exit\""
    echo "Waiting for USB write and readback verification in Terminal.app..."
    while [ ! -f "$STATUS_FILE" ]; do
        sleep 2
    done
    status=$(cat "$STATUS_FILE")
    if [ "$status" != "SUCCESS" ]; then
        echo "flash-usb: Flash process reported failure!" >&2
        exit 4
    fi
fi
echo "flash-usb: GoldenGate OS written and SHA-256 verified on 16 GB USB stick. Ready to boot Surface Laptop 5!"
