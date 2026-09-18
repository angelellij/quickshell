#!/usr/bin/env python3
# Flips X-GNOME-Autostart-enabled on one ~/.config/autostart/*.desktop file
# (current state passed in as $2, script writes the opposite).
import sys
from pathlib import Path

path, enabled = sys.argv[1], sys.argv[2] == "true"
new_value = not enabled

p = Path(path)
lines = p.read_text(encoding="utf-8").splitlines()
new_lines, found = [], False
for line in lines:
    if line.startswith("X-GNOME-Autostart-enabled"):
        new_lines.append(f"X-GNOME-Autostart-enabled={'true' if new_value else 'false'}")
        found = True
    else:
        new_lines.append(line)
if not found:
    for i, line in enumerate(new_lines):
        if line.strip() == "[Desktop Entry]":
            new_lines.insert(i + 1, f"X-GNOME-Autostart-enabled={'true' if new_value else 'false'}")
            break
p.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
