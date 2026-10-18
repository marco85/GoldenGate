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
