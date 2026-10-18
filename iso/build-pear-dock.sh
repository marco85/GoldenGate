#!/usr/bin/env bash
# Build only the reviewed dock from immutable sources; never enable the pearOS repo.
set -euo pipefail
PROFILE=$1
REV=a82d2a476b165f8921dfc84b0eb805d40462d9b0
SHA=0e7dd43f6b2a2055fadfa73823318590963d580fabcec0533caef56a083fae7c
STAGE=$(mktemp -d /tmp/goldengate-peardock.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
pacman -S --needed --noconfirm cmake ninja extra-cmake-modules qt6-tools vulkan-headers \
    plasma-workspace plasma-activities-stats libksysguard kbookmarks kio knotifications
curl --fail --location --retry 3 "https://codeload.github.com/pearOS-archlinux/pkgbuilds/tar.gz/$REV" -o "$STAGE/source.tar.gz"
printf '%s  %s\n' "$SHA" "$STAGE/source.tar.gz" | sha256sum --check
# Include the complete original source in the ISO for license compliance.
install -Dm644 "$STAGE/source.tar.gz" "$PROFILE/airootfs/usr/share/goldengate/sources/pearos-pkgbuilds-$REV.tar.gz"
tar -xzf "$STAGE/source.tar.gz" -C "$STAGE"
SOURCE="$STAGE/pkgbuilds-$REV/pearos-dock"
cmake -S "$SOURCE" -B "$STAGE/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$STAGE/build" --parallel 2
DESTDIR="$PROFILE/airootfs" cmake --install "$STAGE/build"
install -d "$PROFILE/airootfs/usr/share/plasma/plasmoids/PearDock/contents/skins"
cp -a "$SOURCE/package/contents/skins/." "$PROFILE/airootfs/usr/share/plasma/plasmoids/PearDock/contents/skins/"
# Use only standard app launchers; optional pearOS-specific integrations stay disabled.
install -Dm644 /usr/share/licenses/spdx/GPL-2.0-or-later.txt "$PROFILE/airootfs/usr/share/licenses/goldengate-peardock/GPL-2.0-or-later.txt"
