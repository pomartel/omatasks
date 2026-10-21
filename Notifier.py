# Sends OmaTasks' desktop notifications and reports the buttons pressed on them.
#
# Task names and projects are private, and a process's arguments are readable
# by every user on the machine (/proc/<pid>/cmdline), so requests arrive as
# JSON lines on stdin and answers leave as JSON lines on stdout. The service
# runs the system Python, which has PyGObject on Omarchy.
#
# Each request may name a marker. The first request to create that marker's
# directory sends the notification (mkdir either creates or fails,
# atomically), so a reloaded shell does not repeat this morning's recap.
# Markers live in the runtime directory and are swept after two days.
import json
import os
import shutil
import sys
import time

from gi.repository import Gio, GLib

BASE = os.path.join(os.environ.get('XDG_RUNTIME_DIR') or '/tmp', 'omatasks')
SHOWN = os.path.join(BASE, 'shown')
ICON = os.path.join(BASE, 'icon.svg')
ICON_SVG = ('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
            '<circle cx="64" cy="64" r="54" fill="#dc4c3e"/>'
            '<path d="M38 66l18 18 36-40" fill="none" stroke="#fff" stroke-width="12"'
            ' stroke-linecap="round" stroke-linejoin="round"/></svg>')

sent = {}
pending = [b'']
loop = GLib.MainLoop()


def private(path):
    os.makedirs(path, mode=0o700, exist_ok=True)
    os.chmod(path, 0o700)


def claim(marker):
    if not marker:
        return True
    try:
        private(BASE)
        private(SHOWN)
        for name in os.listdir(SHOWN):
            path = os.path.join(SHOWN, name)
            if os.path.getmtime(path) < time.time() - 2 * 86400:
                shutil.rmtree(path, ignore_errors=True)
        os.mkdir(os.path.join(SHOWN, marker))
        return True
    except OSError:
        return False


def icon():
    try:
        if not os.path.isfile(ICON):
            private(BASE)
            with open(ICON, 'w') as f:
                f.write(ICON_SVG)
        return ICON
    except OSError:
        return ''


def notify(request):
    marker = ''.join(c if c.isalnum() or c in '-_' else '_' for c in str(request.get('marker', '')))[:200]
    if not claim(marker):
        return
    actions = []
    for key, label in request.get('actions', []):
        actions += [str(key), str(label)]
    hints = {'urgency': GLib.Variant('y', 2 if request.get('urgent') else 1)}
    try:
        nid = bus.call_sync(
            'org.freedesktop.Notifications', '/org/freedesktop/Notifications',
            'org.freedesktop.Notifications', 'Notify',
            GLib.Variant('(susssasa{sv}i)', ('OmaTasks', 0, icon(), str(request['title']),
                                             # The server reads the body as markup.
                                             GLib.markup_escape_text(str(request.get('body', ''))),
                                             actions, hints, -1)),
            GLib.VariantType('(u)'), Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        sent[nid] = str(request.get('id', ''))
    except GLib.Error:
        pass


def answered(connection, sender, path, iface, signal, params, data):
    nid = params[0]
    if nid not in sent:
        return
    if signal == 'ActionInvoked':
        print(json.dumps({'id': sent[nid], 'action': params[1]}), flush=True)
    elif signal == 'NotificationClosed':
        sent.pop(nid, None)


def read(fd, condition):
    chunk = os.read(fd, 65536)
    if not chunk:
        loop.quit()
        return False
    pending[0] += chunk
    while b'\n' in pending[0]:
        line, pending[0] = pending[0].split(b'\n', 1)
        try:
            notify(json.loads(line))
        except (ValueError, KeyError, TypeError):
            pass
    return True


bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
bus.signal_subscribe('org.freedesktop.Notifications', 'org.freedesktop.Notifications', None,
                     '/org/freedesktop/Notifications', None, Gio.DBusSignalFlags.NONE, answered, None)
GLib.io_add_watch(sys.stdin.fileno(), GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP, read)
loop.run()
