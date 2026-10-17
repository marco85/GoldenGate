# GoldenGate OS — Surface Laptop 5 Installation Guide

This guide walks through flashing the **16 GB USB installer**, booting the **Surface Laptop 5 (13.5", Model 1950)**, testing hardware in the live session, installing GoldenGate OS, and enrolling **Face ID** and **iPhone AirDrop**.

---

## Step 1: Write the ISO to the 16 GB USB Stick (on your Mac)

1. Plug the **16 GB USB stick** into your Mac (leave `SANDISK USB` connected).
2. Run:
   ```sh
   cd "/Volumes/SANDISK USB/GoldenGate"
   sh tools/make-boot-usb.sh
   ```
3. `flash-usb.sh` automatically refuses your internal SSD and refuses `SANDISK USB`, asks you to confirm the 16 GB USB disk identifier (e.g. `disk5`), writes the ISO with `dd`, and verifies the SHA-256 checksum.

---

## Step 2: Prepare Surface Laptop 5 UEFI (Disable Secure Boot for First Boot)

1. On the Surface Laptop 5, hold **Shift** while clicking **Restart** (or power on while holding **Volume Up**) to open **Surface UEFI**.
2. Go to **Security → Secure Boot** → Click **Change configuration** → Select **None** (temporarily off for installation; the First-Boot Setup Assistant re-enrolls the `linux-surface` Secure Boot MOK key afterward).
3. Go to **Boot configuration** → Drag **USB Storage** to the top of the boot order.
4. Plug in the **16 GB USB stick**, then click **Exit → Restart now**.

---

## Step 3: Live Session Hardware Verification & Installation

1. The laptop boots through the **Apple-style Golden Gate Plymouth splash** directly into the **macOS 27 Golden Gate Live Desktop** at `150%` fractional scaling (`2256×1504`).
2. The **Surface Laptop 5 Live Checklist** opens automatically so you can verify before wiping the disk:
   - Keyboard & `Ctrl` / `Alt` (`⌘ Command`) shortcuts
   - Two-finger trackpad scrolling (smooth, dampened macOS inertia) & 3/4-finger gestures
   - 10-point PixelSense touchscreen (`iptsd`)
   - Wi-Fi & Bluetooth
   - Speakers & brightness keys
   - Front RGB & IR Camera (`/dev/video*`)
   - Sleep & wake (`s2idle`)
3. Click **Install GoldenGate OS** to launch the macOS Recovery-styled **Calamares Installer**:
   - Select Language (`English` or `한국어`)
   - Confirm Timezone (`America/New_York`) and Keyboard
   - Enter her name, username, and password
   - Confirm **Erase Disk (`ext4`)** and click **Install Now** (~4 minutes).
4. When finished, click **Restart Now** and remove the 16 GB USB stick.

---

## Step 4: First-Boot Golden Gate Setup Assistant

On first login via the **Golden Gate Lock Screen**, the **Setup Assistant** walks through:
1. **Wi-Fi Connection**
2. **Face ID (IR Camera) Enrollment**: Pulses the Surface Laptop 5 IR emitter (`linux-enable-ir-emitter`) and scans her face with `howdy` so she can unlock the Lock Screen, `sudo`, and system prompts just by looking at the laptop.
3. **Liquid Glass Customization**: Preview and adjust the **Liquid Glass Slider** (`0%` Tinted Opaque to `100%` Liquid Glass Refraction) and Dark / Light / Auto mode.
4. **AirDrop & iPhone Continuity Pairing**: Displays an instant QR code on screen to connect her iPhone via **LocalSend**, **Safari Zero-App AirDrop**, and **KDE Connect** (for shared iPhone↔Mac clipboard and notifications).
5. **AI & App Sign-In + Secure Boot MOK**: Sign into **Antigravity**, **Claude**, and **ChatGPT/Codex**, and optionally enroll the `linux-surface` Secure Boot key.
