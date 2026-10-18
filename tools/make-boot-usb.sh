#!/bin/sh
# make-boot-usb.sh -- One-command watch, download, reassemble, and flash for the GoldenGate OS 16 GB Boot USB on macOS
#
# Usage:
#   sh tools/make-boot-usb.sh              # Uses newest out/*.iso, or downloads from GitHub Release
#   sh tools/make-boot-usb.sh --download   # Forces downloading newest ISO from GitHub Release v27.0-latest
#   sh tools/make-boot-usb.sh --watch      # Watches the live GitHub Actions build until done, then downloads & flashes
set -eu

top=$(cd "$(dirname "$0")/.." && pwd)
cd "$top"

echo "=== GoldenGate OS (macOS 27 Golden Gate) — 16 GB Boot USB Maker ==="

if ! command -v gh >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/gh ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -x /usr/local/bin/gh ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
fi

mkdir -p out

if [ "${1:-}" = "--watch" ]; then
    echo "Checking active GitHub Actions run..."
    ACTIVE_ID=$(gh run list --workflow=build.yml --limit 1 --json databaseId --jq '.[0].databaseId' || true)
    if [ -n "$ACTIVE_ID" ]; then
        echo "Watching build run $ACTIVE_ID (press Ctrl+C to stop watching)..."
        gh run watch "$ACTIVE_ID" --exit-status
    fi
    set -- "--download"
fi

LATEST_ISO=$(ls -t out/*.iso 2>/dev/null | head -n 1 || true)

if [ "${1:-}" = "--download" ] || [ -z "$LATEST_ISO" ]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo "Error: GitHub CLI (gh) not found and no local ISO in out/." >&2
        exit 1
    fi
    echo "Checking GitHub Releases for v27.0-latest ISO..."
    if gh release view v27.0-latest >/dev/null 2>&1; then
        echo "Downloading GoldenGate OS ISO from GitHub Release v27.0-latest into out/..."
        download_dir=$(mktemp -d "$top/out/.download.XXXXXX")
        trap 'rm -rf "$download_dir"' EXIT
        gh release download v27.0-latest -D "$download_dir" --clobber
        set -- "$download_dir"/*.iso.sha256
        if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
            echo "Error: Release must contain exactly one ISO checksum; nothing will be written." >&2
            exit 2
        fi
        SHA_FILE=$1
        ISO_NAME=$(basename "$SHA_FILE" .sha256)
        echo "Reassembling $ISO_NAME and verifying SHA-256 checksum..."
        cat "$download_dir/${ISO_NAME}".part-* > "$download_dir/$ISO_NAME"
        # Bind the single digest to the complete ISO, never to a downloaded chunk.
        if ! awk -v filename="$ISO_NAME" 'NR != 1 || NF != 2 || length($1) != 64 || $1 ~ /[^0-9a-fA-F]/ || $2 != filename { bad=1 } END { exit bad || NR != 1 }' "$SHA_FILE"; then
            echo "Error: Invalid ISO checksum record; nothing will be written." >&2
            exit 2
        fi
        expected=$(awk '{ print tolower($1) }' "$SHA_FILE")
        actual=$(shasum -a 256 "$download_dir/$ISO_NAME" | cut -d' ' -f1)
        [ "$actual" = "$expected" ] || { echo "Error: ISO checksum mismatch; nothing will be written." >&2; exit 2; }
        mv "$download_dir/$ISO_NAME" "out/$ISO_NAME"
        mv "$SHA_FILE" "out/${ISO_NAME}.sha256"
        LATEST_ISO="out/$ISO_NAME"
    else
        STATUS=$(gh run list --workflow=build.yml --limit 1 --json status,conclusion,databaseId --jq '.[0] | "\(.status) (\(.conclusion // "running")) [ID: \(.databaseId)]"' || true)
        echo "Build is not finished yet. Latest run status: ${STATUS:-unknown}"
        echo "Tip: Run 'sh tools/make-boot-usb.sh --watch' to watch live progress until it finishes!"
        exit 2
    fi
fi

if [ -z "$LATEST_ISO" ] || [ ! -f "$LATEST_ISO" ]; then
    echo "Error: No ISO image found in out/*.iso." >&2
    exit 2
fi

echo "Ready to flash: $LATEST_ISO"
sh tools/flash-usb.sh "$LATEST_ISO"
