#!/usr/bin/env python3
"""UEFI live boot, full offline install, then boot the installed virtual SATA disk.
All writes are confined to a fresh temporary QEMU qcow2; never use host disks.
"""
import os
import subprocess
import tempfile
from pathlib import Path
import pexpect

root = Path(__file__).resolve().parents[2]
iso = max((root / 'out').glob('*.iso'), key=lambda p: p.stat().st_mtime)
firmware = '/usr/share/OVMF/OVMF_CODE_4M.fd'
def expect_pattern(vm, success_pattern, timeout=120):
    patterns = [
        success_pattern,
        r'Traceback \(most recent call last\):',
        r'AssertionError:',
        r'INSTALL_RESULT False',
        r'\[root@goldengate [^\]]*\]#',
        r'\[ggtest@goldengate [^\]]*\]\$',
    ]
    idx = vm.expect(patterns, timeout=timeout)
    if idx != 0:
        output = (vm.before or '') + (vm.after or '')
        try:
            output += vm.read_nonblocking(size=8192, timeout=2)
        except Exception:
            pass
        raise RuntimeError(f"Expected {success_pattern!r} but encountered {patterns[idx]!r}:\n{output}")

with tempfile.TemporaryDirectory(prefix='goldengate-boot-') as temp:
    disk = str(Path(temp) / 'target.qcow2')
    subprocess.run(['qemu-img', 'create', '-f', 'qcow2', disk, '28G'], check=True)
    nvram = str(Path(temp) / 'OVMF_VARS.fd')
    import shutil
    shutil.copyfile('/usr/share/OVMF/OVMF_VARS_4M.fd', nvram)
    base = ['qemu-system-x86_64', '-enable-kvm', '-m', '4096', '-smp', '2', '-drive', f'if=pflash,format=raw,readonly=on,file={firmware}',
            '-drive', f'if=pflash,format=raw,file={nvram}',
            '-display', 'none', '-serial', 'stdio', '-monitor', 'none', '-no-reboot',
            '-drive', f'file={disk},format=qcow2,if=ide', '-net', 'none']
    with (root / 'out/boot-test.log').open('w') as log:
        vm = pexpect.spawn(base[0], base[1:] + ['-cdrom', str(iso), '-boot', 'd'], encoding='utf-8', timeout=300)
        vm.logfile = log
        try:
            vm.expect('login:')
            vm.sendline('root')
            vm.expect('Password:')
            vm.sendline('goldengate')
            vm.expect(r'[#] ')
            import base64
            qml_data = base64.b64encode(b"import QtQuick\nimport PearDock\nItem { Backend {} }").decode()
            qml_check = f"import base64; from PyQt6.QtGui import QGuiApplication; from PyQt6.QtQml import QQmlEngine, QQmlComponent; from PyQt6.QtCore import QUrl; a=QGuiApplication([]); e=QQmlEngine(); c=QQmlComponent(e); c.setData(base64.b64decode('{qml_data}'),QUrl()); o=c.create(); print('DOCK_QML_VALID' if o else [err.toString() for err in c.errors()])"
            encoded = base64.b64encode(qml_check.encode()).decode()
            vm.sendline(f'QT_QPA_PLATFORM=offscreen python -c "import base64; exec(base64.b64decode(\'{encoded}\'))"')
            expect_pattern(vm, r'DOCK_QML_VALID\r+\n', timeout=60)
            vm.expect(r'[#] ')
            applet_check = Path(__file__).with_name('dock_runtime.py').read_bytes()
            encoded = base64.b64encode(applet_check).decode()
            vm.sendline(f'python -c "import base64; exec(base64.b64decode(\'{encoded}\'))"')
            expect_pattern(vm, r'DOCK_APPLET_VALID\r+\n', timeout=60)
            vm.expect(r'[#] ')
            command = "import runpy; m=runpy.run_path('/usr/bin/goldengate-installer'); ok=m['execute_install']('/dev/sda','ggtest',\"Golden O'Brien\",'BootTest-123'); print('INSTALL_RESULT',ok)"
            import base64
            encoded = base64.b64encode(command.encode()).decode()
            vm.sendline(f'python -c "import base64; exec(base64.b64decode(\'{encoded}\'))"')
            expect_pattern(vm, r'INSTALL_RESULT True', timeout=600)
            vm.expect(r'[#] ')
            # Add a serial console only to the VM target, for installed login verification.
            vm.sendline("mount /dev/sda2 /mnt; mount /dev/sda1 /mnt/boot/efi; sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/c\\GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0,115200\"' /mnt/etc/default/grub; arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg; umount -R /mnt; poweroff")
            vm.expect(pexpect.EOF, timeout=120)
        finally:
            vm.close(force=True)
        vm = pexpect.spawn(base[0], base[1:] + ['-boot', 'c'], encoding='utf-8', timeout=300)
        vm.logfile = log
        try:
            vm.expect('login:')
            vm.sendline('ggtest')
            vm.expect('Password:')
            vm.sendline('BootTest-123')
            vm.expect(r'[$] ')
            vm.sendline("test ! -e /etc/sudoers.d/99-live && ! id live >/dev/null 2>&1 && test -f /boot/grub/grub.cfg && test -d /usr/share/plasma/plasmoids/PearDock && printf '\\nINSTALLED_BOOT_VERIFIED\\n'")
            expect_pattern(vm, r'INSTALLED_BOOT_VERIFIED', timeout=60)
            print('UEFI live boot, offline installation and installed account login verified.')
        finally:
            vm.close(force=True)
