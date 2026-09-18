#!/usr/bin/env python3
# Creates ~/.config/textual-config/commands/<name>.sh, executable.
# Prints the new path on success (for $() capture); errors go to stderr.
import sys
from pathlib import Path

name = sys.argv[1]
d = Path.home() / ".config/textual-config/commands"
d.mkdir(parents=True, exist_ok=True)
path = d / f"{name}.sh"

if path.exists():
    print(f"{path.name} ya existe", file=sys.stderr)
    sys.exit(1)

path.write_text("#!/bin/bash\n\n")
path.chmod(0o755)
print(str(path))
