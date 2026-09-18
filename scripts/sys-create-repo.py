#!/usr/bin/env python3
# Creates /etc/apt/sources.list.d/<name>.list with the given deb line.
# Prints the new path on success (for $() capture); errors go to stderr.
import subprocess
import sys
from pathlib import Path

name, deb = sys.argv[1], sys.argv[2]
path = Path("/etc/apt/sources.list.d") / f"{name}.list"

if subprocess.run(["sudo", "test", "-e", str(path)]).returncode == 0:
    print(f"{path.name} ya existe", file=sys.stderr)
    sys.exit(1)

r = subprocess.run(["sudo", "tee", str(path)], input=deb.strip() + "\n", capture_output=True, text=True)
if r.returncode != 0:
    print(r.stderr.strip(), file=sys.stderr)
    sys.exit(1)
print(str(path))
