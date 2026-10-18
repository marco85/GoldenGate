"""Run only inside the disposable live VM; restore the applet after instrumentation."""
from pathlib import Path
import os
import signal
import subprocess
import tempfile
p = Path('/usr/share/plasma/plasmoids/PearDock/contents/ui/main.qml')
assert not os.environ.get('QT_STYLE_OVERRIDE')
assert os.environ.get('QT_QUICK_CONTROLS_STYLE') == 'org.kde.desktop'
original = p.read_text()
marker = '    Component.onCompleted: {'
index = original.rfind(marker)
assert index >= 0
try:
    instrumented = original[:index] + original[index:].replace(marker, marker + '\n        console.log("GOLDENGATE_DOCK_READY");', 1)
    p.write_text(instrumented)
    # D-Bus-activated helpers can retain inherited pipes after the applet exits.
    # Use a file-backed log and bound the entire private session's lifetime.
    with tempfile.TemporaryFile() as log:
        process = subprocess.Popen(['dbus-run-session', '--', 'plasmawindowed', 'PearDock'], env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software'}, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            process.wait(timeout=35)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
        finally:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        log.seek(0)
        output = log.read().decode(errors='replace')
    assert 'GOLDENGATE_DOCK_READY' in output and 'error when loading applet' not in output, output
    print('DOCK_APPLET_VALID', flush=True)
finally:
    p.write_text(original)
