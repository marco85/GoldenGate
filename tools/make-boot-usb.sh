#!/bin/sh
# make-boot-usb.sh -- One-command watch, download, and flash for the GoldenGate OS 16 GB Boot USB on macOS
#
# Usage:
#   sh tools/make-boot-usb.sh              # Uses newest out/*.iso, or downloads from GitHub Actions
#   sh tools/make-boot-usb.sh --download   # Forces downloading newest ISO artifact from GitHub Actions
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
    echo "Checking GitHub Actions for the latest goldengate-iso artifact..."
    RUN_ID=$(gh run list --workflow=build.yml --status=success --limit 5 --json databaseId --jq '.[0].databaseId' || true)
    if [ -z "$RUN_ID" ]; then
        STATUS=$(gh run list --workflow=build.yml --limit 1 --json status,conclusion,databaseId --jq '.[0] | "\(.status) (\(.conclusion // "running")) [ID: \(.databaseId)]"' || true)
        echo "Build is not finished yet. Latest run status: ${STATUS:-unknown}"
        echo "Tip: Run 'sh tools/make-boot-usb.sh --watch' to watch live progress until it finishes!"
        exit 2
    fi
    echo "Downloading goldengate-iso from run $RUN_ID into out/..."
    gh run download "$RUN_ID" -n goldengate-iso -D out/ --clobber
    LATEST_ISO=$(ls -t out/*.iso 2>/dev/null | head -n 1)
fi

if [ -z "$LATEST_ISO" ] || [ ! -f "$LATEST_ISO" ]; then
    echo "Error: No ISO image found in out/*.iso." >&2
    exit 2
fi

echo "Ready to flash: $LATEST_ISO"
sh tools/flash-usb.sh "$LATEST_ISO"
