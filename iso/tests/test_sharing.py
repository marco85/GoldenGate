"""Exercise the real HTTP handler on loopback with temporary user data."""
import runpy
import http.client
import threading
from pathlib import Path
import pytest
import importlib.machinery
import importlib.util

script = Path(__file__).parents[1] / 'profile/airootfs/usr/bin/goldengate-airdrop'

@pytest.fixture
def sharing(tmp_path, monkeypatch):
    loader = importlib.machinery.SourceFileLoader('sharing', str(script))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    monkeypatch.setattr(module, 'STATE_FILE', tmp_path / 'state.json')
    monkeypatch.setattr(module, 'DOWNLOADS_DIR', tmp_path / 'Downloads')
    monkeypatch.setattr(module, 'notify_airdrop_received', lambda *args: None)
    server = module.http.server.ThreadingHTTPServer(('127.0.0.1', 0), module.SafariAirDropHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield module, server
    server.shutdown()
    server.server_close()


def test_upload_off_is_rejected(sharing):
    module, server = sharing
    module.save_airdrop_state({'mode': 'off'})
    conn = http.client.HTTPConnection(*server.server_address)
    conn.request('POST', '/upload', b'anything', {'Content-Type':'multipart/form-data; boundary=x'})
    assert conn.getresponse().status == 403
    conn.close()
    assert not module.DOWNLOADS_DIR.exists()


def test_upload_never_overwrites_existing_file(sharing):
    module, server = sharing
    module.save_airdrop_state({'mode': 'everyone'})
    module.DOWNLOADS_DIR.mkdir()
    (module.DOWNLOADS_DIR / 'photo.txt').write_bytes(b'original')
    body = b'--x\r\nContent-Disposition: form-data; name="file"; filename="photo.txt"\r\nContent-Type: text/plain\r\n\r\nnew\r\n--x--\r\n'
    conn = http.client.HTTPConnection(*server.server_address)
    conn.request('POST', '/upload', body, {'Content-Type':'multipart/form-data; boundary=x'})
    assert conn.getresponse().status == 200
    conn.close()
    assert (module.DOWNLOADS_DIR / 'photo.txt').read_bytes() == b'original'
    assert sorted(p.read_bytes() for p in module.DOWNLOADS_DIR.iterdir()) == [b'new', b'original']
