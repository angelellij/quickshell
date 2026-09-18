#!/usr/bin/env python3
# Writes one key into ~/.config/textual-config/settings.json (shared with
# the textual-config TUI, so changing it here also changes it there).
import json
import sys
from pathlib import Path

key, value = sys.argv[1], sys.argv[2]
path = Path.home() / ".config/textual-config/settings.json"
path.parent.mkdir(parents=True, exist_ok=True)

try:
    settings = json.loads(path.read_text())
except Exception:
    settings = {"editor": "nvim", "theme": "textual-dark"}

settings[key] = value
path.write_text(json.dumps(settings, indent=2))
