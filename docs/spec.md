# GoldenGate OS — Design & Implementation Specification

*Written 2026-10-17. An Arch Linux + KDE Plasma 6 (Wayland) clone of **macOS 27 "Golden Gate"**, engineered specifically for the **Microsoft Surface Laptop 5 (13.5", Model 1950)**.*

---

## 1. Project Goal & Success Criteria

Build a complete, hardware-optimized Linux clone of **macOS 27 "Golden Gate"** for Marcus's wife's **Surface Laptop 5 (13.5", Model 1950)** that boots and installs cleanly from a **16 GB USB stick**.

**Success means:**
- **Authentic macOS 27 "Golden Gate" Look & Feel**:
  - **Liquid Glass Engine & Interactive Slider**: Real-time background refraction/blur (`kwin-effects-better-blur-dx` / `forceblur`) with darkened depth edges, subtle HDR specular rim highlights, and a live **Liquid Glass Slider** in Control Center & System Settings that shifts between maximum glass translucency and high-contrast tinted opacity.
  - **Golden Gate Refinements**: Standardized, dialed-back `10px` window corner radii, uniform toolbars, edge-to-edge full-height sidebars with **colored sidebar icons** (Finder/Dolphin, System Settings, GTK4/Qt6), **Menu Bar Clutter Control** (auto-collapsing tray overflow), and floating glass Dock.
- **Native MacBook Trackpad & PixelSense Touchscreen Feel**:
  - **Fixed Two-Finger Scrolling**: Custom `libinput` quirks + KWin Wayland `ScrollFactor=0.35` dampening + kinetic momentum curves so two-finger scrolling is never uncontrollably fast and matches native macOS inertia.
  - **1:1 Multi-Touch Gestures**: 3/4-finger swipe up for Mission Control, 3/4-finger swipe down for App Exposé & browser pull-to-refresh, 3/4-finger swipe left/right for Desktop Spaces, 4-finger pinch for Launchpad, 4-finger spread for Show Desktop, and 2-finger right-edge swipe for Notification Center.
- **Thorough Window Snapping, Copy-Paste & AirDrop**:
  - **Window Snapping**: Drag-to-edge/corner glass snap zones (left/right halves, top/bottom halves, quarters, top-edge fill) with optional `8px` macOS tile margins, `Option (Alt) + Drag` quick-tile, green traffic-light tile menu, and keyboard shortcuts (`Ctrl+Alt+Arrows`).
  - **Surface-Friendly Hybrid Copy-Paste**: Both physical **`Ctrl`** (what she sees printed on the Surface keyboard) AND **`Alt`** (next to the Spacebar, Mac `⌘ Command` muscle memory) work seamlessly as `⌘ Command` for `C/V/X/A/Z/S/F/W/T/Q/Space`, with context-aware Terminal Copy/Paste (`Ctrl+V` / `Alt+V` pastes in Terminal; `Alt+C` / `Ctrl+Shift+C` copies in Terminal), `wl-clip-persist` so copied data never vanishes when closing an app, Finder file `Ctrl+C`/`Ctrl+V`, and `Ctrl+Shift+V` Glass Clipboard History.
  - **3-Engine AirDrop & iPhone Continuity**: Custom macOS 27 **AirDrop Radar Glass App** wired into the Finder sidebar, right-click `"Share via AirDrop..."`, Dock drag-and-drop, and Control Center; powered by background **LocalSend** auto-receive (`~/Downloads` + notification chime), a **Zero-App Safari QR AirDrop Server** (any iPhone can send/receive in Safari without installing an app), and **KDE Connect** (Universal Clipboard sync & iPhone notifications).
- **Surface Laptop 5 Hardware & IR Camera ("Face ID")**:
  - **`linux-surface` Kernel + `iptsd`**: Full keyboard, precision touchpad, 10-point PixelSense touchscreen, Surface Pen, battery health, and Alder Lake `s2idle` deep sleep.
  - **IR Camera Face ID**: `howdy` + `linux-enable-ir-emitter` bound to the Surface Laptop 5's USB UVC IR camera (`045e:0965`) for `<0.8s` facial unlock across SDDM Login, Lock Screen, Polkit GUI prompts, and `sudo`, with guided enrollment in the First-Boot Setup Assistant.
- **Full Daily App Suite & Multilingual Input**:
  - **Antigravity App v2.24.0 (GUI)** (`/opt/antigravity`) + **Antigravity CLI v1.4.0** (`agy` / `antigravity`) pre-installed and pinned to the Dock.
  - **Google Chrome** (Safari Golden Gate theme + Iris Xe VA-API), **Claude Desktop + Claude Code CLI**, **ChatGPT / Codex CLI**, **LibreOffice**, **Finder Spacebar Quick Look**, **macOS Screenshot HUD (`Ctrl+Shift+3/4/5`)**, and **Visual Intelligence Overlay (`Ctrl+Shift+Space`)**.
  - **English / 한국어 (Korean) / 日本語 (Japanese)** input switching via `fcitx5-hangul` and `fcitx5-mozc`.

---

## 2. Target Hardware Profile (Surface Laptop 5)

| Component | Specification | GoldenGate OS Implementation |
|---|---|---|
| **Model** | Microsoft Surface Laptop 5, 13.5", Model 1950 | `linux-surface` kernel + `surface-control` + `linux-surface-secureboot-mok` |
| **CPU** | Intel Core i5-1235U (12th-gen Alder Lake, 2P+8E, 10 cores) | `intel-ucode`, `thermald`, `power-profiles-daemon`, Alder Lake P/E-core scheduler |
| **RAM** | 8 GB LPDDR5x | `zram-generator` (zstd, 50% RAM = 4 GB), `systemd-oomd`, idle RAM target `< 1.1 GB` |
| **GPU** | Intel Iris Xe Graphics | `mesa`, `vulkan-intel`, `intel-media-driver` (`LIBVA_DRIVER_NAME=iHD`) |
| **Display** | 13.5" PixelSense 2256×1504 (3:2, ~201 PPI, 10-point touch) | KWin Wayland native `1.5x` (150%) fractional scale + `iptsd` touch/pen daemon |
| **Cameras** | Front RGB (`045e:0964`) + Front IR (`045e:0965`) USB UVC | `uvcvideo` + `linux-enable-ir-emitter` + `howdy` PAM Face ID integration |
| **Wi-Fi / BT** | Intel Wi-Fi 6 AX201 (`iwlwifi`) + Bluetooth 5.1 | `linux-firmware`, NetworkManager, BlueZ, Avahi mDNS (`_airdrop._tcp` / LocalSend) |
| **Storage** | 256 GB NVMe SSD | Clean `ext4` root (`noatime`, `fstrim.timer`) via macOS-styled Calamares Erase & Install |
| **Sleep** | Modern Standby (`s2idle`) | `mem_sleep_default=s2idle i915.enable_psr=1` + sleep/wake hook verification |

---

## 3. Repository Structure

```text
GoldenGate/
  docs/
    spec.md                         # Full architecture & hardware specification
    install-guide.md                # Step-by-step USB boot, install & Face ID guide
  iso/
    build.sh                        # Builds custom AUR packages, bundles Antigravity, runs mkarchiso
    profile/                        # archiso profile (profiledef.sh, pacman.conf, packages.x86_64)
      airootfs/                     # Complete root filesystem overlay for live & installed OS
        etc/                        # PAM (Face ID), libinput quirks, xremap, sddm, calamares, skel
        usr/
          bin/                      # goldengate-* binaries (liquid-glass, airdrop, faceid, quicklook, etc.)
          share/                    # Plasma GoldenGate layout, SDDM theme, Plymouth splash, icons, sounds
    tests/
      test_config.py                # Static verification of ISO configs, hardware quirks, and scripts
      test_image.py                 # Post-build ISO content & size (<3.8 GB FAT32/16GB USB) verification
      boot_test.sh                  # Headless QEMU OVMF UEFI boot verification
  welcome/
    goldengate_welcome/             # First-Boot macOS 27 Setup Assistant & Live Hardware Checklist
    tests/                          # Unit tests for Setup Assistant, Face ID, Liquid Glass, and AirDrop
  tools/
    flash-usb.sh                    # Safe macOS USB writer (protects SANDISK USB, verifies SHA-256)
    make-boot-usb.sh                # Downloads latest GitHub Actions ISO artifact & flashes 16 GB USB
  .github/
    workflows/
      build.yml                     # CI pipeline: tests -> archiso build -> image test -> QEMU boot -> artifact
```
