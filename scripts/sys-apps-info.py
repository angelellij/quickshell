#!/usr/bin/env python3
# Emits repos/startup-apps/default-apps/commands for the Sys > Apps sub-tab,
# mirroring the logic in the textual-config repo's
# App/Logic/{repos,startup,default_apps,commands}.py (kept standalone here
# since that's a separate application, not a dependency).
import configparser
import json
from pathlib import Path

SOURCES_LIST = Path("/etc/apt/sources.list")
SOURCES_DIR = Path("/etc/apt/sources.list.d")
AUTOSTART_DIR = Path.home() / ".config/autostart"
MIMEAPPS = Path.home() / ".config/mimeapps.list"
COMMANDS_DIR = Path.home() / ".config/textual-config/commands"

COMMON_MIMES = [
    ("text/html", "Web Browser"),
    ("x-scheme-handler/http", "HTTP Handler"),
    ("x-scheme-handler/https", "HTTPS Handler"),
    ("x-scheme-handler/mailto", "Email Client"),
    ("image/png", "Image Viewer"),
    ("video/mp4", "Video Player"),
    ("audio/mpeg", "Audio Player"),
    ("application/pdf", "PDF Viewer"),
    ("text/plain", "Text Editor"),
    ("inode/directory", "File Manager"),
]


def read(path):
    try:
        return path.read_text()
    except Exception:
        return ""


def parse_list(fpath):
    repos = []
    for i, line in enumerate(read(fpath).splitlines()):
        stripped = line.strip()
        if not stripped:
            continue
        enabled = not stripped.startswith("#")
        deb_line = stripped.lstrip("#").strip()
        if not deb_line.startswith(("deb ", "deb-src ")):
            continue
        parts = deb_line.split()
        if len(parts) < 3:
            continue
        idx = 1
        if parts[idx].startswith("["):
            while idx < len(parts) and not parts[idx].endswith("]"):
                idx += 1
            idx += 1
        url = parts[idx] if idx < len(parts) else ""
        suite = parts[idx + 1] if idx + 1 < len(parts) else ""
        repos.append({"file": str(fpath), "line_num": i, "enabled": enabled, "format": "list", "url": url, "suite": suite})
    return repos


def parse_sources(fpath):
    repos = []
    for stanza in read(fpath).split("\n\n"):
        fields = {}
        for line in stanza.splitlines():
            if ":" in line and not line.startswith(" "):
                k, _, v = line.partition(":")
                fields[k.strip()] = v.strip()
        if not fields:
            continue
        uris, suites = fields.get("URIs", ""), fields.get("Suites", "")
        if not uris or not suites:
            continue
        enabled = fields.get("Enabled", "yes").lower() not in ("no", "false", "0")
        repos.append({"file": str(fpath), "line_num": 0, "enabled": enabled, "format": "sources", "url": uris.split()[0], "suite": suites.split()[0]})
    return repos


def get_repos():
    repos = []
    files = [SOURCES_LIST] + sorted(SOURCES_DIR.glob("*.list")) + sorted(SOURCES_DIR.glob("*.sources"))
    for fpath in files:
        if not fpath.exists():
            continue
        repos.extend(parse_sources(fpath) if fpath.suffix == ".sources" else parse_list(fpath))
    return repos


def get_startup():
    AUTOSTART_DIR.mkdir(parents=True, exist_ok=True)
    apps = []
    for f in sorted(AUTOSTART_DIR.glob("*.desktop")):
        cp = configparser.ConfigParser(interpolation=None)
        cp.read(f, encoding="utf-8")
        sec = "Desktop Entry"
        if not cp.has_section(sec):
            continue
        enabled_val = cp.get(sec, "X-GNOME-Autostart-enabled", fallback="true")
        apps.append({"name": cp.get(sec, "Name", fallback=f.stem), "enabled": enabled_val.lower() != "false", "path": str(f)})
    return apps


def read_mimeapps():
    if not MIMEAPPS.exists():
        return {}
    result, in_default = {}, False
    for line in MIMEAPPS.read_text().splitlines():
        line = line.strip()
        if line == "[Default Applications]":
            in_default = True
            continue
        if line.startswith("["):
            in_default = False
            continue
        if in_default and "=" in line:
            mime, apps = line.split("=", 1)
            result[mime.strip()] = apps.split(";")[0].strip()
    return result


def get_default_apps():
    current = read_mimeapps()
    return [{"mime": m, "label": l, "app": current.get(m, "")} for m, l in COMMON_MIMES]


def get_commands():
    if not COMMANDS_DIR.exists():
        return []
    return [{"name": f.stem, "path": str(f)} for f in sorted(COMMANDS_DIR.glob("*.sh"))]


print(json.dumps({
    "repos": get_repos(),
    "startup": get_startup(),
    "default_apps": get_default_apps(),
    "commands": get_commands(),
}))
