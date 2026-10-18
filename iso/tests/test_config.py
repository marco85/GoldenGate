"""
GoldenGate OS — Comprehensive Architecture, Hardware & Feature Verification Suite
Tests all subsystems of the macOS 27 "Golden Gate" Arch Linux clone for Surface Laptop 5.
"""
from __future__ import annotations
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / "iso" / "profile"
AIROOTFS = PROFILE / "airootfs"
BIN_DIR = AIROOTFS / "usr" / "bin"


def test_archiso_profile_and_surface_kernel():
    profiledef = (PROFILE / "profiledef.sh").read_text(encoding="utf-8")
    assert 'iso_name="goldengate"' in profiledef
    assert "'-comp' 'zstd' '-Xcompression-level' '19'" in profiledef

    pacman_conf = (PROFILE / "pacman.conf").read_text(encoding="utf-8")
    assert "[linux-surface]" in pacman_conf
    assert "https://pkg.surfacelinux.com/arch/" in pacman_conf

    packages = (PROFILE / "packages.x86_64").read_text(encoding="utf-8").splitlines()
    pkg_set = {line.strip() for line in packages if line.strip() and not line.strip().startswith("#")}
    for required in (
        "linux-surface",
        "iptsd",
        "plasma-desktop",
        "kwin",
        "sddm",
        "dolphin",
        "konsole",
        "kvantum",
        "wl-clipboard",
        "cliphist",
        "fcitx5-hangul",
        "fcitx5-mozc",
        "libreoffice-fresh",
        "kdeconnect",
        "zram-generator",
        "thermald",
        "power-profiles-daemon",
        "intel-media-driver",
        "plymouth",
    ):
        assert required in pkg_set, f"Missing required package: {required}"


def test_trackpad_two_finger_scroll_dampening_and_surface_touch():
    kcminput = (AIROOTFS / "etc" / "skel" / ".config" / "kcminputrc").read_text(encoding="utf-8")
    assert "NaturalScroll=true" in kcminput
    assert "ScrollFactor=0.35" in kcminput
    assert "TapToClick=true" in kcminput

    quirks = (AIROOTFS / "etc" / "libinput" / "local-overrides.quirks").read_text(encoding="utf-8")
    assert "0x045E" in quirks
    assert "AttrPalmPressureThreshold=130" in quirks

    iptsd = (AIROOTFS / "etc" / "iptsd.conf").read_text(encoding="utf-8")
    assert "DisableOnPalm = true" in iptsd
    assert "DisableOnStylus = true" in iptsd


def test_liquid_glass_slider_and_golden_gate_appearance():
    with tempfile.TemporaryDirectory() as tmp:
        res = subprocess.run(
            [
                sys.executable,
                str(BIN_DIR / "goldengate-liquid-glass"),
                "--set-level",
                "85",
                "--mode",
                "dark",
                "--radius",
                "10",
                "--tile-margins",
                "8",
                "--root",
                tmp,
                "--status",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(res.stdout)
        assert data["state"]["glass_level"] == 85
        assert data["state"]["corner_radius"] == 10
        assert data["state"]["colored_sidebars"] is True
        assert data["metrics"]["blur_strength"] >= 12

        gtk4_css = (Path(tmp) / ".config" / "gtk-4.0" / "gtk.css").read_text(encoding="utf-8")
        assert "border-radius: 10px;" in gtk4_css
        assert "-gtk-icon-style: regular;" in gtk4_css


def test_window_snapping_to_sides_and_corners():
    kwinrc = (AIROOTFS / "etc" / "skel" / ".config" / "kwinrc").read_text(encoding="utf-8")
    assert "ButtonsOnLeft=XIA" in kwinrc
    assert "ElectricBorderTiling=true" in kwinrc
    assert "ElectricBorderCornerRatio=0.25" in kwinrc

    for zone in ("left", "right", "top", "bottom", "top-left", "top-right", "bottom-left", "bottom-right", "maximize", "center"):
        res = subprocess.run(
            [sys.executable, str(BIN_DIR / "goldengate-window-snap"), zone, "--dry-run", "--margin", "8"],
            capture_output=True,
            text=True,
            check=True,
        )
        payload = json.loads(res.stdout)
        geom = payload["geometry"]
        assert geom["w"] > 0 and geom["h"] > 0
        assert geom["x"] >= 8 and geom["y"] >= 36


def test_multitouch_gestures():
    gestures_conf = (AIROOTFS / "etc" / "skel" / ".config" / "libinput-gestures.conf").read_text(encoding="utf-8")
    assert "mission-control" in gestures_conf
    assert "app-expose" in gestures_conf
    assert "launchpad" in gestures_conf
    assert "show-desktop" in gestures_conf

    for g in ("mission-control", "app-expose", "space-left", "space-right", "launchpad", "show-desktop", "pull-refresh"):
        res = subprocess.run(
            [sys.executable, str(BIN_DIR / "goldengate-gesture-handler"), g, "--dry-run"],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(res.stdout)
        assert data["gesture"] == g


def test_hybrid_ctrl_and_alt_copy_paste():
    xremap = (AIROOTFS / "etc" / "goldengate" / "xremap.yml").read_text(encoding="utf-8")
    # Terminal smart paste for both Ctrl+V and Alt+V
    assert "C-v: C-Shift-v" in xremap
    assert "M-v: C-Shift-v" in xremap
    # Global Mac muscle memory (Alt next to Spacebar -> Ctrl)
    assert "M-c: C-c" in xremap
    assert "M-v: C-v" in xremap

    konsolerc = (AIROOTFS / "etc" / "skel" / ".config" / "konsolerc").read_text(encoding="utf-8")
    assert "paste=Ctrl+V; Ctrl+Shift+V" in konsolerc


def test_airdrop_suite_and_finder_integration():
    servicemenu = (AIROOTFS / "usr" / "share" / "kio" / "servicemenus" / "goldengate-airdrop.desktop").read_text(encoding="utf-8")
    assert "Share via AirDrop" in servicemenu
    assert "/usr/bin/goldengate-airdrop --send %F" in servicemenu

    places = (AIROOTFS / "etc" / "skel" / ".local" / "share" / "user-places.xbel").read_text(encoding="utf-8")
    assert "<title>AirDrop</title>" in places


def test_surface_ir_camera_faceid_and_pam():
    res = subprocess.run(
        [sys.executable, str(BIN_DIR / "goldengate-faceid-setup"), "--detect"],
        capture_output=True,
        text=True,
        check=True,
    )
    detected = json.loads(res.stdout)
    assert "device" in detected and detected["device"].startswith("/dev/video")

    for pam_file in ("sddm", "kde", "sudo", "polkit-1"):
        content = (AIROOTFS / "etc" / "pam.d" / pam_file).read_text(encoding="utf-8")
        assert "pam_howdy.so" in content

    sddm_qml = (AIROOTFS / "usr" / "share" / "sddm" / "themes" / "goldengate" / "Main.qml").read_text(encoding="utf-8")
    assert "userModel.data(userModel.index(0, 0), Qt.UserRole + 1)" in sddm_qml
    assert "onLoginFailed" in sddm_qml
    assert "faceIdState" in sddm_qml
    assert "shackle" in sddm_qml
    assert "shakeAnimation" in sddm_qml
    assert "30D158" in sddm_qml


def test_iphone_and_macos_sound_suite():
    packages = (PROFILE / "packages.x86_64").read_text(encoding="utf-8").splitlines()
    pkg_set = {line.strip() for line in packages if line.strip() and not line.strip().startswith("#")}
    for ipkg in ("usbmuxd", "libimobiledevice", "ifuse", "gvfs-afc", "kio-extras", "pv"):
        assert ipkg in pkg_set, f"Missing iPhone/system package: {ipkg}"

    sounds_dir = AIROOTFS / "usr" / "share" / "sounds" / "goldengate"
    for s in ("boot-chime.wav", "faceid-unlock.wav", "airdrop.wav", "screenshot.wav", "trash.wav", "volume-pop.wav", "power-plug.wav"):
        assert (sounds_dir / s).is_file(), f"Missing macOS sound effect: {s}"

    places = (AIROOTFS / "etc" / "skel" / ".local" / "share" / "user-places.xbel").read_text(encoding="utf-8")
    assert "iCloud Drive" in places
    assert (AIROOTFS / "usr" / "share" / "applications" / "icloud-drive.desktop").is_file()


def test_grub_and_syslinux_initrd():
    grub_cfg = (PROFILE / "grub" / "grub.cfg").read_text(encoding="utf-8")
    assert "intel-ucode.img" not in grub_cfg
    assert "initramfs-linux-surface.img" in grub_cfg

    syslinux_cfg = (PROFILE / "syslinux" / "syslinux.cfg").read_text(encoding="utf-8")
    assert "intel-ucode.img" not in syslinux_cfg
    assert "initramfs-linux-surface.img" in syslinux_cfg




def test_antigravity_and_cfc_toolbox_integration():
    build_sh = (ROOT / "iso" / "build.sh").read_text(encoding="utf-8")
    assert "2.24.0-5780333019398144/linux-x64/Antigravity.tar.gz" in build_sh
    assert "https://antigravity.google/cli/install.sh" in build_sh

    res = subprocess.run(
        [sys.executable, str(BIN_DIR / "goldengate-toolbox"), "--search", "Blip"],
        capture_output=True,
        text=True,
        check=True,
    )
    items = json.loads(res.stdout)
    assert any(x["name"] == "Blip" for x in items)


def test_calamares_ext4_no_timemachine_and_safe_usb_flasher():
    partition_conf = (AIROOTFS / "etc" / "calamares" / "modules" / "partition.conf").read_text(encoding="utf-8")
    assert 'defaultFileSystemType:  "ext4"' in partition_conf
    assert "btrfs" not in partition_conf.lower()

    flash_sh = (ROOT / "tools" / "flash-usb.sh").read_text(encoding="utf-8")
    assert "SANDISK USB" in flash_sh
    assert "LIMIT=64000000000" in flash_sh


def test_archiso_mkinitcpio_live_hooks():
    archiso_conf = (AIROOTFS / "etc" / "mkinitcpio.conf.d" / "archiso.conf").read_text(encoding="utf-8")
    assert "archiso" in archiso_conf
    assert "archiso_loop_mnt" in archiso_conf

    mkinit_conf = (AIROOTFS / "etc" / "mkinitcpio.conf").read_text(encoding="utf-8")
    assert "archiso" in mkinit_conf
    assert "surface_aggregator" in mkinit_conf

    preset = (AIROOTFS / "etc" / "mkinitcpio.d" / "linux-surface.preset").read_text(encoding="utf-8")
    assert "/boot/vmlinuz-linux-surface" in preset
    assert "/boot/initramfs-linux-surface.img" in preset

    customize = (AIROOTFS / "root" / "customize_airootfs.sh").read_text(encoding="utf-8")
    assert "mkinitcpio -P" in customize
    assert "root:goldengate" in customize


def test_goldengate_installer_and_power_profile():
    # Verify native GoldenGate SSD installer dry-run
    res = subprocess.run(
        [sys.executable, str(BIN_DIR / "goldengate-installer"), "--dry-run", "/dev/nvme0n1"],
        capture_output=True,
        text=True,
        check=True,
    )
    plan = json.loads(res.stdout)
    assert plan["filesystem"] == "ext4"
    assert plan["efi_partition"] == "/dev/nvme0n1p1"
    assert plan["root_partition"] == "/dev/nvme0n1p2"

    # Verify Surface All-Day Battery & 1-Click Performance Boost manager
    res_pwr = subprocess.run(
        [sys.executable, str(BIN_DIR / "goldengate-power-profile"), "--status"],
        capture_output=True,
        text=True,
        check=True,
    )
    pwr = json.loads(res_pwr.stdout)
    assert "mode" in pwr and "ppd_profile" in pwr and pwr["auto_brightness"] is True

    # Verify QuickLook Live Text OCR support and macOS desktop polish files
    ql_text = (BIN_DIR / "goldengate-quicklook").read_text(encoding="utf-8")
    assert "tesseract" in ql_text
    assert "Copy Text from Image (Live Text)" in ql_text
    assert (AIROOTFS / "usr" / "share" / "aurorae" / "themes" / "WhiteSur-dark" / "WhiteSur-darkrc").is_file()
    assert (AIROOTFS / "usr" / "share" / "wallpapers" / "GoldenGate" / "contents" / "images" / "2256x1504.svg").is_file()
    assert (AIROOTFS / "etc" / "skel" / "Desktop" / "goldengate-installer.desktop").is_file()

    # Verify Breeze Dark plasma theme and high-res vector icons
    packages = (PROFILE / "packages.x86_64").read_text(encoding="utf-8").splitlines()
    pkg_set = {line.strip() for line in packages if line.strip() and not line.strip().startswith("#")}
    assert "breeze" in pkg_set
    assert "breeze-icons" in pkg_set

    kdeglobals = (AIROOTFS / "etc" / "skel" / ".config" / "kdeglobals").read_text(encoding="utf-8")
    assert "BreezeDark" in kdeglobals
    assert "activeBackground" in kdeglobals

    plasmarc = (AIROOTFS / "etc" / "skel" / ".config" / "plasmarc").read_text(encoding="utf-8")
    assert "breeze-dark" in plasmarc

    assert (AIROOTFS / "usr" / "share" / "icons" / "hicolor" / "scalable" / "apps" / "apple-logo.svg").is_file()
    layout_js = (AIROOTFS / "usr" / "share" / "plasma" / "layout-templates" / "org.kde.plasma.desktop.goldenGateLayout" / "contents" / "layout.js").read_text(encoding="utf-8")
    assert "apple-logo" in layout_js
    assert 'dock.lengthMode = "fit"' in layout_js


