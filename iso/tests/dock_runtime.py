"""Run only inside the disposable live VM; restore the applet after instrumentation."""
from pathlib import Path
import os
import subprocess
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
    result = subprocess.run(['dbus-run-session', '--', 'timeout', '35s', 'plasmawindowed', 'PearDock'], env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software'}, capture_output=True, text=True, timeout=50)
    output = result.stdout + result.stderr
    assert 'GOLDENGATE_DOCK_READY' in output and 'error when loading applet' not in output, output
    print('DOCK_APPLET_VALID', flush=True)
finally:
    p.write_text(original)
