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
assert index >= 0, f"Marker '{marker}' not found in {p}"
try:
    injection = '''
        console.warn("GOLDENGATE_DOCK_READY");
        console.log("GOLDENGATE_DOCK_READY");
        if (typeof Qt !== "undefined" && Qt.callLater) {
            Qt.callLater(Qt.quit);
        }'''
    instrumented = original[:index] + original[index:].replace(marker, marker + injection, 1)
    p.write_text(instrumented)
    # D-Bus-activated helpers can retain inherited pipes after the applet exits.
    # Use a file-backed log and bound the entire private session's lifetime.
    with tempfile.TemporaryFile() as log:
        env = {
            **os.environ,
            'QT_QPA_PLATFORM': 'offscreen',
            'QT_QUICK_BACKEND': 'software',
            'XDG_CURRENT_DESKTOP': 'KDE',
            'QT_FORCE_STDERR_LOGGING': '1',
            'QT_LOGGING_RULES': 'qml.debug=true;qt.qml.*=true;*.debug=true',
        }
        process = subprocess.Popen(
            ['dbus-run-session', '--', 'plasmawindowed', 'PearDock'],
            env=env,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        try:
            process.wait(timeout=25)
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
    assert 'GOLDENGATE_DOCK_READY' in output, f"GOLDENGATE_DOCK_READY marker missing. Log output:\n{output}"
    assert 'error when loading applet' not in output.lower(), f"Applet loading error detected:\n{output}"
    print('DOCK_APPLET_VALID', flush=True)
finally:
    p.write_text(original)

