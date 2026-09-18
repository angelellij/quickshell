#!/usr/bin/env python3
# Deletes an app launcher .desktop entry. If it's ours (under
# ~/.local/share/applications) just unlink it; if it's a system one we
# can't remove, hide it with a local Hidden=true override instead
# (same approach as textual-config's apps.py delete_app).
import sys
from pathlib import Path

LOCAL_DIR = Path.home() / ".local/share/applications"
path = Path(sys.argv[1])

if str(path).startswith(str(LOCAL_DIR)):
    path.unlink(missing_ok=True)
else:
    LOCAL_DIR.mkdir(parents=True, exist_ok=True)
    (LOCAL_DIR / path.name).write_text("[Desktop Entry]\nHidden=true\n")
