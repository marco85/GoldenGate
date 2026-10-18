#!/usr/bin/env python3
"""Inspect the actual delivered filesystem, not only its source profile."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
iso = max((root / 'out').glob('*.iso'), key=lambda p: p.stat().st_mtime)
with tempfile.TemporaryDirectory() as temp:
    sfs = str(Path(temp) / 'root.sfs')
    subprocess.run(['xorriso', '-osirrox', 'on', '-indev', str(iso), '-extract', '/arch/x86_64/airootfs.sfs', sfs], check=True)
    listing = subprocess.check_output(['unsquashfs', '-ll', sfs], text=True)
    for entry in ('usr/bin/goldengate-installer', 'usr/bin/unsquashfs', 'usr/bin/arch-chroot', 'usr/bin/grub-install', 'usr/bin/systemsettings', 'usr/share/plasma/plasmoids/PearDock/metadata.json', 'usr/lib/qt6/qml/PearDock/wavetaskplugin.so', 'usr/lib/qt6/qml/PearDock/libwavetask.so', 'home/live', 'etc/sudoers.d/99-live'):
        assert f'/{entry}' in listing, f'Missing ISO content: {entry}'
    # Read the installed copy, proving the safety fix actually reached the image.
    installer = subprocess.check_output(['unsquashfs', '-cat', sfs, 'usr/bin/goldengate-installer'], text=True)
    assert 'preflight(disk_dev, username, full_name, password, hostname)' in installer
    print('ISO filesystem contents verified.')
