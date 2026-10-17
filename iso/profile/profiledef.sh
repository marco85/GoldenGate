#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="goldengate"
iso_label="GOLDENGATE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="GoldenGate OS <https://github.com/marco85/GoldenGate>"
iso_application="GoldenGate OS (macOS 27 Golden Gate Clone for Surface Laptop 5)"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux'
  'uefi.grub'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/sudoers.d/goldengate"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/bin/goldengate-session"]="0:0:755"
  ["/usr/bin/goldengate-liquid-glass"]="0:0:755"
  ["/usr/bin/goldengate-airdrop"]="0:0:755"
  ["/usr/bin/goldengate-airdrop-daemon"]="0:0:755"
  ["/usr/bin/goldengate-faceid-setup"]="0:0:755"
  ["/usr/bin/goldengate-quicklook"]="0:0:755"
  ["/usr/bin/goldengate-visual-intelligence"]="0:0:755"
  ["/usr/bin/goldengate-window-snap"]="0:0:755"
  ["/usr/bin/goldengate-gesture-handler"]="0:0:755"
  ["/usr/bin/goldengate-clipboard-daemon"]="0:0:755"
  ["/usr/bin/goldengate-welcome"]="0:0:755"
  ["/usr/bin/goldengate-live-checklist"]="0:0:755"
  ["/usr/bin/goldengate-post-install"]="0:0:755"
  ["/usr/bin/goldengate-toolbox"]="0:0:755"
)
