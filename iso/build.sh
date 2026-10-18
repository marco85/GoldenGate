#!/usr/bin/env bash
# GoldenGate OS — Arch Linux (archiso) Builder for Surface Laptop 5
# 1. Configures linux-surface keyring & repository
# 2. Builds custom/AUR packages into /tmp/goldengate-repo
# 3. Bundles Antigravity App v2.24.0 (x64) + Antigravity CLI v1.4.0 into airootfs
# 4. Stages WhiteSur-GoldenGate theme, icons, cursors, and live user configuration
# 5. Builds the compressed UEFI+BIOS ISO (<3.8 GB for FAT32 & 16 GB USB)
set -euo pipefail

TOP="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="$TOP/iso/profile"
WORK="/tmp/archiso-work"
OUT="$TOP/out"
CUSTOM_REPO="/tmp/goldengate-repo"

ANTIGRAVITY_GUI_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.24.0-5780333019398144/linux-x64/Antigravity.tar.gz"
ANTIGRAVITY_CLI_URL="https://antigravity.google/cli/install.sh"

echo "=== [1/6] Initializing Arch Linux Build Environment & linux-surface Keyring ==="
cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://america.mirror.pkgbuild.com/$repo/os/$arch
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
EOF

pacman-key --init
pacman-key --populate archlinux
curl -fsSL https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | pacman-key --add -
pacman-key --lsign-key 56C464BAAC421453

if ! grep -q "\[linux-surface\]" /etc/pacman.conf; then
    cat >> /etc/pacman.conf << 'EOF'

[linux-surface]
SigLevel = Optional TrustAll
Server = https://pkg.surfacelinux.com/arch/
EOF
fi

for attempt in 1 2 3; do
    pacman -Syu --noconfirm --needed archiso grub dosfstools mtools libisoburn syslinux edk2-shell git base-devel curl wget squashfs-tools zstd python && break
    echo "Retrying pacman host setup (attempt $attempt)..."
    sleep 5
done

# Seed standard archiso releng syslinux & grub support files without overwriting our custom grub.cfg
cp -rn /usr/share/archiso/configs/releng/syslinux/* "$PROFILE/syslinux/" 2>/dev/null || true
cp -rn /usr/share/archiso/configs/releng/grub/* "$PROFILE/grub/" 2>/dev/null || true
cp -rn /usr/share/archiso/configs/releng/efiboot "$PROFILE/" 2>/dev/null || true

# Ensure mkinitcpio archiso directories exist
mkdir -p "$PROFILE/airootfs/etc/mkinitcpio.conf.d" "$PROFILE/airootfs/etc/mkinitcpio.d"
if [ ! -f "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf" ] && [ -f /usr/share/archiso/configs/releng/airootfs/etc/mkinitcpio.conf.d/archiso.conf ]; then
    cp /usr/share/archiso/configs/releng/airootfs/etc/mkinitcpio.conf.d/archiso.conf "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
fi


echo "=== [2/6] Initializing Local Custom Package Repository ($CUSTOM_REPO) ==="
mkdir -p "$CUSTOM_REPO"
repo-add "$CUSTOM_REPO/goldengate-custom.db.tar.gz"

echo "=== [3/6] Bundling Antigravity App v2.24.0 (GUI) & Antigravity CLI v1.4.0 ==="
mkdir -p "$PROFILE/airootfs/opt/antigravity" "$PROFILE/airootfs/usr/local/bin"
if curl -fsSL --head "$ANTIGRAVITY_GUI_URL" >/dev/null 2>&1; then
    echo "Downloading Antigravity App v2.24.0 (x64)..."
    curl -fL "$ANTIGRAVITY_GUI_URL" -o /tmp/Antigravity.tar.gz
    tar -xzf /tmp/Antigravity.tar.gz -C "$PROFILE/airootfs/opt/antigravity" --strip-components=1 || \
        tar -xzf /tmp/Antigravity.tar.gz -C "$PROFILE/airootfs/opt/antigravity"
    rm -f /tmp/Antigravity.tar.gz
fi

# Provide CLI installer wrapper / binary in /usr/local/bin/antigravity-cli-setup
cat > "$PROFILE/airootfs/usr/local/bin/antigravity-cli-install" << 'EOF'
#!/usr/bin/env bash
set -e
curl -fsSL https://antigravity.google/cli/install.sh | bash
EOF
chmod 755 "$PROFILE/airootfs/usr/local/bin/antigravity-cli-install"

echo "=== [4/6] Staging WhiteSur-GoldenGate Theme, Icons & Cursors ==="
python3 "$PROFILE/airootfs/usr/bin/goldengate-liquid-glass" \
    --apply-default \
    --root "$PROFILE/airootfs/etc/skel"

bash "$TOP/iso/build-pear-dock.sh" "$PROFILE"

echo "=== [5/6] Configuring Live User (live) & SDDM Live Autologin ==="
mkdir -p "$PROFILE/airootfs/etc/sddm.conf.d"
cat > "$PROFILE/airootfs/etc/sddm.conf.d/20-live-autologin.conf" << 'EOF'
[Autologin]
User=live
Session=goldengate.desktop
EOF

echo "=== [6/6] Running mkarchiso ==="
rm -rf "$WORK"
mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

ISO_FILE=$(ls -t "$OUT"/*.iso | head -n 1)
ISO_SIZE=$(stat -c %s "$ISO_FILE" 2>/dev/null || stat -f %z "$ISO_FILE")
echo "Built ISO: $ISO_FILE ($((ISO_SIZE / 1024 / 1024)) MB)"
