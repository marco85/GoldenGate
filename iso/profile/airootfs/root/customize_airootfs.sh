#!/usr/bin/env bash
# GoldenGate OS — archiso chroot customization hook (customize_airootfs.sh)
# Executed automatically by mkarchiso inside the target airootfs before building squashfs.
set -e -u

# 1. Generate English, Korean, and Japanese UTF-8 locales
sed -i 's/^#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(ko_KR\.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(ja_JP\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "goldengate" > /etc/hostname

# 2. Create the live session user ("live") with full Golden Gate skel & groups
if ! id -u live >/dev/null 2>&1; then
    useradd -m -G wheel,video,audio,input,uucp,storage,optical,network,power -s /bin/bash live
    passwd -d live >/dev/null 2>&1 || true
fi
cp -rn /etc/skel/. /home/live/ 2>/dev/null || true
chown -R live:live /home/live

# Passwordless sudo for the live user during live USB session
echo "live ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-live
chmod 440 /etc/sudoers.d/99-live

# 3. Ensure PAM fallback if pam_howdy.so is not yet enrolled in live session
for pam_f in /etc/pam.d/sddm /etc/pam.d/kde /etc/pam.d/sudo /etc/pam.d/polkit-1; do
    if [ -f "$pam_f" ]; then
        sed -i 's/^auth[[:space:]]\+sufficient[[:space:]]\+pam_howdy\.so/-auth        sufficient  pam_howdy.so/' "$pam_f"
    fi
done

# 4. Link Antigravity GUI binary to /usr/local/bin/antigravity if present
if [ -x /opt/antigravity/antigravity ]; then
    ln -sf /opt/antigravity/antigravity /usr/local/bin/antigravity
elif [ -x /opt/antigravity/Antigravity ]; then
    ln -sf /opt/antigravity/Antigravity /opt/antigravity/antigravity
    ln -sf /opt/antigravity/Antigravity /usr/local/bin/antigravity
fi

# 5. Enable core system & Surface Laptop 5 services
for svc in sddm NetworkManager bluetooth avahi-daemon iptsd thermald power-profiles-daemon systemd-oomd; do
    systemctl enable "$svc" 2>/dev/null || true
done

# 6. Set root password for emergency/rescue debugging and ensure live user has no password
echo "root:goldengate" | chpasswd
passwd -d live >/dev/null 2>&1 || true

# 7. Generate live initramfs with archiso hooks for linux-surface kernel
mkinitcpio -P

