# GoldenGate OS — macOS 27 "Golden Gate" Clone for Surface Laptop 5

**GoldenGate OS** is a hardware-optimized **Arch Linux (`archiso`) + KDE Plasma 6 (Wayland)** operating system engineered specifically for the **Microsoft Surface Laptop 5 (13.5", Model 1950)**, replicating the look, feel, gestures, and ecosystem of **macOS 27 "Golden Gate"**.

## Highlights

- **macOS 27 "Golden Gate" Liquid Glass UI**:
  - Live **Liquid Glass Slider** (`goldengate-liquid-glass`) controlling KWin `better-blur-dx` / `forceblur` refraction, darkened window edges, HDR specular highlights, and glass tint opacity.
  - Dialed-back **10px uniform corner radii**, uniform toolbars, and **edge-to-edge full-height sidebars with colored icons** across Finder (Dolphin), GTK3/GTK4, and Qt6/Kvantum.
  - **Menu Bar Clutter Control** (Global Menu + auto-collapsing system tray overflow), centered **Floating Glass Dock**, **Spotlight (`Ctrl+Space` / `Alt+Space`)**, and **Visual Intelligence Overlay (`Ctrl+Shift+Space`)**.
- **Native MacBook Trackpad & PixelSense Touchscreen**:
  - **Calibrated Two-Finger Scrolling**: Custom `libinput` quirks + Wayland `ScrollFactor=0.35` dampening + kinetic inertia curves eliminate fast/uncontrollable Linux touchpad scrolling.
  - **1:1 Multi-Touch Gestures**: 3/4-finger swipe up (Mission Control), down (App Exposé & browser pull-to-refresh), left/right (Spaces), 4-finger pinch (Launchpad), 4-finger spread (Show Desktop), and 2-finger right-edge swipe (Notification Center).
- **Window Snapping, Hybrid Copy-Paste & 3-Engine AirDrop**:
  - **Window Snapping**: Drag to sides/corners/top with glass preview zones, optional `8px` macOS tile margins, `Option+Drag` quick-tile, and `Ctrl+Alt+Arrow` shortcuts.
  - **Surface-Friendly Copy-Paste**: Both physical **`Ctrl`** (printed on the Surface keyboard) and **`Alt`** (next to Spacebar, Mac `⌘` position) work as `⌘ Command` across all apps, with smart Terminal Copy/Paste, `wl-clip-persist` persistent clipboard, Finder file `Ctrl+C`/`Ctrl+V`, and `Ctrl+Shift+V` Glass Clipboard History.
  - **Thorough AirDrop & iPhone Continuity (`goldengate-airdrop`)**: Finder sidebar + right-click `"Share via AirDrop..."` + Dock drop target + Control Center toggle, backed by background **LocalSend** auto-receive, a **Zero-App Safari QR AirDrop Server**, and **KDE Connect** iPhone Universal Clipboard & notifications.
- **Surface Laptop 5 Hardware & IR Camera ("Face ID")**:
  - Pre-configured `linux-surface` kernel, `iptsd` touchscreen/pen daemon, Alder Lake `s2idle` deep sleep, `zram` (50% RAM), and Intel Iris Xe VA-API hardware video decoding.
  - **IR Camera Face ID (`goldengate-faceid-setup`)**: Uses `howdy` + `linux-enable-ir-emitter` on the Surface Laptop 5 USB UVC IR camera (`045e:0965`) for `<0.8s` facial unlock on the SDDM Golden Gate Lock Screen, Polkit GUI dialogs, and `sudo`.
- **Pre-Bundled Daily Apps & Multilingual Input**:
  - **Antigravity App v2.24.0 (GUI)** + **Antigravity CLI v1.4.0 (`agy`)**
  - **Google Chrome**, **Claude Desktop + Claude Code CLI**, **ChatGPT / Codex CLI**, **LibreOffice**, **Finder Spacebar Quick Look**, and **macOS Screenshot HUD (`Ctrl+Shift+3/4/5`)**
  - **English / 한국어 (Korean) / 日本語 (Japanese)** input switching via `fcitx5-hangul` and `fcitx5-mozc`

## Quick Start: Flashing the 16 GB Boot USB

```sh
# Download the latest verified ISO from GitHub Actions and flash the 16 GB USB stick
sh tools/make-boot-usb.sh --download
```

See [`docs/spec.md`](docs/spec.md) for the full technical architecture and [`docs/install-guide.md`](docs/install-guide.md) for the step-by-step installation guide.
