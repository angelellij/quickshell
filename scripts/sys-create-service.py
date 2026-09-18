#!/usr/bin/env python3
# Creates /etc/systemd/system/<name>.service from a minimal template (needs
# pkexec). Prints the new path on success (for $() capture); errors to stderr.
import subprocess
import sys
from pathlib import Path

TEMPLATE = "[Unit]\nDescription=\n\n[Service]\nExecStart=\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target\n"

name = sys.argv[1]
path = Path("/etc/systemd/system") / f"{name}.service"

if path.exists():
    print(f"{path.name} ya existe", file=sys.stderr)
    sys.exit(1)

r = subprocess.run(["pkexec", "tee", str(path)], input=TEMPLATE, capture_output=True, text=True)
if r.returncode != 0:
    print(r.stderr.strip(), file=sys.stderr)
    sys.exit(1)
subprocess.run(["pkexec", "systemctl", "daemon-reload"])
print(str(path))
