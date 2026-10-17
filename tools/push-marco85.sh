#!/bin/sh
# push-marco85.sh -- Logs into GitHub CLI as marco85 (if needed), creates marco85/GoldenGate,
# pushes the repository, and watches the GitHub Actions ISO build live.
set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
top=$(cd "$(dirname "$0")/.." && pwd)
cd "$top"

ACTIVE_USER=$(gh api user --jq '.login' 2>/dev/null || true)
if [ "$ACTIVE_USER" != "marco85" ]; then
    echo "=== Logging into GitHub CLI as marco85 ==="
    gh auth login -h github.com -p https -w
fi

gh auth setup-git

if ! gh repo view marco85/GoldenGate >/dev/null 2>&1; then
    echo "=== Creating private repository marco85/GoldenGate ==="
    git remote remove origin 2>/dev/null || true
    gh repo create marco85/GoldenGate --private --source=. --remote=origin --push
else
    git remote set-url origin https://github.com/marco85/GoldenGate.git 2>/dev/null || \
        git remote add origin https://github.com/marco85/GoldenGate.git
    git push -u origin main
fi

echo ""
echo "=== Pushed to https://github.com/marco85/GoldenGate ==="
echo "Starting live ISO build watcher (sh tools/make-boot-usb.sh --watch)..."
sleep 5
sh tools/make-boot-usb.sh --watch
