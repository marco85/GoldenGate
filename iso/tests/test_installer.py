"""Installer boundary tests: never run partition tools on the host."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import pytest

SCRIPT = Path(__file__).parents[1] / 'profile/airootfs/usr/bin/goldengate-installer'
loader = importlib.machinery.SourceFileLoader('installer', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
installer = importlib.util.module_from_spec(spec)
loader.exec_module(installer)


def disks(monkeypatch, entries, live='sdb'):
    monkeypatch.setattr(installer, 'get_live_boot_device', lambda: live)
    monkeypatch.setattr(installer, 'internal_topology', lambda _: True)
    monkeypatch.setattr(installer.shutil, 'which', lambda _: '/usr/bin/lsblk')
    monkeypatch.setattr(installer.subprocess, 'run', lambda *a, **k: SimpleNamespace(returncode=0, stdout=json.dumps({'blockdevices': entries})))
    return installer.list_installable_disks()


def block(name, **changes):
    return dict(name=name, size=256_000_000_000, model='SSD', tran='nvme', rm=False, ro=False, type='disk', **changes)


def test_no_disks_never_invents_surface_ssd(monkeypatch):
    assert disks(monkeypatch, []) == []


def test_only_writable_internal_disks(monkeypatch):
    entries = [block('nvme0n1'), {**block('sda'), 'tran': 'usb'}, {**block('sdc'), 'rm': True}, {**block('sdd'), 'ro': True}, block('sdb')]
    assert [d['device'] for d in disks(monkeypatch, entries)] == ['/dev/nvme0n1']


def test_unknown_boot_source_fails_closed(monkeypatch):
    assert disks(monkeypatch, [block('nvme0n1')], live='') == []


@pytest.mark.parametrize('username,password,hostname', [('root','password1','surface'), ('-bad','password1','surface'), ('live','password1','surface'), ('sarah','abc','surface'), ('sarah','abc\ndefgh','surface'), ('sarah','password1','bad name')])
def test_invalid_account_inputs(username, password, hostname):
    with pytest.raises(ValueError):
        installer.validate_account(username, "Sarah O'Brien", password, hostname)


def test_apostrophe_in_name_is_valid():
    installer.validate_account('sarah', "Sarah O'Brien", 'secure:password', 'surface')


def test_rejected_target_never_invokes_partition_tools(monkeypatch):
    calls = []
    monkeypatch.setattr(installer, 'list_installable_disks', lambda: [])
    monkeypatch.setattr(installer.subprocess, 'run', lambda *a, **k: calls.append(a))
    assert installer.execute_install('/dev/nvme0n1', 'sarah', 'Sarah', 'password1') is False
    assert calls == []


def test_existing_system_account_rejected_before_erasure():
    with pytest.raises(ValueError):
        installer.validate_account('daemon', 'My Name', 'password1', 'surface')


def test_existing_system_group_rejected_before_erasure():
    with pytest.raises(ValueError):
        installer.validate_account('wheel', 'My Name', 'password1', 'surface')


def test_external_pci_topology_is_rejected(tmp_path):
    pci = tmp_path / 'devices/pci0000:00/0000:00:07.0'
    device = pci / '0000:01:00.0/nvme/nvme0/nvme0n1'
    device.mkdir(parents=True)
    (pci / 'external_facing').write_text('1\n')
    root = tmp_path / 'block'
    root.mkdir()
    (root / 'nvme0n1').symlink_to(device)
    assert installer.internal_topology('nvme0n1', root) is False


def test_unknown_topology_rejected(tmp_path):
    assert installer.internal_topology('nvme0n1', tmp_path) is False


def test_internal_pci_topology_allowed(tmp_path):
    pci = tmp_path / 'devices/pci0000:00/0000:00:1d.0'
    device = pci / '0000:01:00.0/nvme/nvme0/nvme0n1'
    device.mkdir(parents=True)
    (pci / 'external_facing').write_text('0\n')
    root = tmp_path / 'block'
    root.mkdir()
    (root / 'nvme0n1').symlink_to(device)
    assert installer.internal_topology('nvme0n1', root) is True
