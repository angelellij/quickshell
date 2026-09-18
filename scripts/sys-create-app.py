#!/usr/bin/env python3
# Creates ~/.local/share/applications/<name>.desktop from a minimal template.
# Prints the new path on success (for $() capture); errors go to stderr.
import sys
from pathlib import Path

name = sys.argv[1]
d = Path.home() / ".local/share/applications"
d.mkdir(parents=True, exist_ok=True)
filename = name if name.endswith(".desktop") else f"{name}.desktop"
path = d / filename

if path.exists():
    print(f"{filename} ya existe", file=sys.stderr)
    sys.exit(1)

path.write_text(
    "[Desktop Entry]\n"
    "Type=Application\n"
    f"Name={name}\n"
    "Exec=\n"
    "Icon=application-x-executable\n"
    "Categories=Other;\n"
    "Comment=\n"
    "Terminal=false\n"
)
print(str(path))
