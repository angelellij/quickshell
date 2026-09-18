#!/usr/bin/env python3
# Toggles one apt repo entry on/off (flips whatever "enabled" it currently
# has, passed in as $4). Needs sudo to write under /etc/apt.
import subprocess
import sys
from pathlib import Path

file, line_num, fmt, enabled = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4] == "true"
path = Path(file)


def write(target, content):
    subprocess.run(["sudo", "tee", target], input=content, capture_output=True, text=True)


if fmt == "sources":
    lines = path.read_text().splitlines()
    value = "no" if enabled else "yes"
    found = False
    for i, line in enumerate(lines):
        if line.startswith("Enabled:"):
            lines[i] = f"Enabled: {value}"
            found = True
            break
    if not found:
        for i, line in enumerate(lines):
            if line.startswith("Types:"):
                lines.insert(i + 1, f"Enabled: {value}")
                break
    write(file, "\n".join(lines) + "\n")
else:
    lines = path.read_text().splitlines()
    if enabled:
        lines[line_num] = "# " + lines[line_num]
    else:
        lines[line_num] = lines[line_num].lstrip("#").strip()
    write(file, "\n".join(lines) + "\n")
