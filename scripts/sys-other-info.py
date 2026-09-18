#!/usr/bin/env python3
# Emits editor/theme settings + locale info + installed fonts for the
# Sys > Other sub-tab, mirroring textual-config's App/Logic/
# {settings,locale,fonts}.py (kept standalone here, that's a separate app).
import json
import shutil
import subprocess
from pathlib import Path

SETTINGS_FILE = Path.home() / ".config/textual-config/settings.json"
FONTS_DIR = Path.home() / ".local/share/fonts"
FONT_EXTS = {".ttf", ".otf", ".woff", ".woff2"}
KNOWN_EDITORS = ["nvim", "vim", "vi", "nano", "emacs", "helix", "hx", "micro", "gedit", "kate", "mousepad", "geany", "code", "zed"]


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return r.stdout
    except Exception:
        return ""


def get_settings():
    try:
        s = {"editor": "nvim", "theme": "textual-dark", **json.loads(SETTINGS_FILE.read_text())}
    except Exception:
        s = {"editor": "nvim", "theme": "textual-dark"}
    s["available_editors"] = [e for e in KNOWN_EDITORS if shutil.which(e)]
    return s


def get_locale():
    info = {"locale": "", "timezone": "", "keyboard": ""}
    for line in run(["localectl", "status"]).splitlines():
        line = line.strip()
        if line.startswith("System Locale:"):
            info["locale"] = line.split(":", 1)[1].strip().replace("LANG=", "")
        elif line.startswith("X11 Layout:"):
            info["keyboard"] = line.split(":", 1)[1].strip()
    for line in run(["timedatectl", "status"]).splitlines():
        line = line.strip()
        if line.startswith("Time zone:"):
            info["timezone"] = line.split(":", 1)[1].strip().split()[0]
    return info


def get_fonts():
    if not FONTS_DIR.exists():
        return []
    return [
        {"name": f.stem, "path": str(f), "format": f.suffix.lstrip(".").upper()}
        for f in sorted(FONTS_DIR.rglob("*")) if f.suffix.lower() in FONT_EXTS
    ]


print(json.dumps({"settings": get_settings(), "locale": get_locale(), "fonts": get_fonts()}))
