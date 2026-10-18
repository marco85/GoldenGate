"""Test the download-to-writer handoff using a fake release and harmless writer."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize('release', ['missing-checksum', 'wrong-checksum', 'valid'])
def test_download_requires_verified_release_before_writer(tmp_path, release):
    (tmp_path / 'tools').mkdir()
    (tmp_path / 'out').mkdir()
    (tmp_path / 'bin').mkdir()
    shutil.copyfile(ROOT / 'tools/make-boot-usb.sh', tmp_path / 'tools/make-boot-usb.sh')
    stale = tmp_path / 'out/old.iso'
    stale.write_bytes(b'old image')
    writer = tmp_path / 'tools/flash-usb.sh'
    writer.write_text('cp "$1" writer-received.iso\n')
    gh = tmp_path / 'bin/gh'
    checksum = hashlib.sha256(b'new image').hexdigest() if release == 'valid' else '0' * 64
    gh.write_text(f'''#!{sys.executable}
import sys
from pathlib import Path
if sys.argv[1:3] == ['release', 'download']:
    folder = Path(sys.argv[sys.argv.index('-D') + 1])
    (folder / 'new.iso.part-aa').write_bytes(b'new image')
    if {release!r} != 'missing-checksum':
        (folder / 'new.iso.sha256').write_text('{checksum}  new.iso\\n')
''')
    gh.chmod(0o755)
    result = subprocess.run(['sh', 'tools/make-boot-usb.sh', '--download'], cwd=tmp_path,
                            env={**os.environ, 'PATH': f'{tmp_path}/bin:' + os.environ['PATH']},
                            capture_output=True, text=True)
    received = tmp_path / 'writer-received.iso'
    assert stale.read_bytes() == b'old image'
    if release == 'valid':
        assert result.returncode == 0, result.stdout + result.stderr
        assert received.read_bytes() == b'new image'
    else:
        assert result.returncode != 0, result.stdout + result.stderr
        assert not received.exists(), 'An unverified or stale image reached the writer'
