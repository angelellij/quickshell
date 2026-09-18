#!/usr/bin/env python3
# Creates ~/.config/autostart/<name>.desktop from a minimal template.
# Prints the new path on success (for $() capture); errors go to stderr.
import sys
from pathlib import Path

name = sys.argv[1]
d = Path.home() / ".config/autostart"
d.mkdir(parents=True, exist_ok=True)
path = d / f"{name}.desktop"

if path.exists():
    print(f"{path.name} ya existe", file=sys.stderr)
    sys.exit(1)

path.write_text(
    "[Desktop Entry]\n"
    "Type=Application\n"
    f"Name={name}\n"
    "Exec=\n"
    "X-GNOME-Autostart-enabled=true\n"
)
print(str(path))
