# GoldenGate OS

An Arch Linux and KDE Plasma desktop tailored for the Surface Laptop 5, with a macOS-inspired top menu bar, floating Pear Dock, dark appearance and multilingual input.

The image includes linux-surface, iptsd, Intel graphics support, Chromium, LibreOffice, KDE Connect and a native offline installer. Installation erases a positively identified internal disk and installs an EFI/ext4 system. It requires UEFI with Secure Boot disabled.

Start with the [installation guide](docs/install-guide.md). Test the live desktop on the actual Surface before erasing Windows. Back up files and save the BitLocker recovery key first.

## Build and verification

Run `bash iso/build.sh` as root inside an x86_64 Arch Linux build environment, or dispatch the build workflow. The pipeline checks configuration and installer behavior, inspects the actual ISO filesystem, boots it under UEFI in QEMU, installs to a temporary virtual disk, and verifies a login to the installed system before publishing.

Run local checks with `python3 -m pytest -q`. These checks alone do not establish bootability or Surface hardware compatibility.

On macOS, `sh tools/make-boot-usb.sh --download` downloads a published image, verifies its checksum and writes the separate 16 GB USB with readback verification. Administrator access is required. The 250 GB SANDISK archive drive is protected.

## Included and optional features

Pear Dock is compiled from pinned upstream sources with compatibility patches; see [provenance](docs/pearos-provenance.md). GoldenGate retains KDE settings and a stock task-manager fallback.

Touchscreen, suspend, camera and trackpad behavior require testing on the physical laptop. Face unlock, LocalSend, xremap, extra gesture daemons and third-party blur effects are not bundled. Web app launchers require internet access and do not imply native AI clients or command-line tools are installed. Local browser sharing is not Apple's AirDrop protocol. Secure Boot is not provisioned by this installer.

The [audit](docs/audit-2026-10-18.md) records the original issues and verification limits. The older [specification](docs/spec.md) describes ambitions and is not a list of verified capabilities.
