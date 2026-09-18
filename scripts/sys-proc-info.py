#!/usr/bin/env python3
# Emits the top processes by CPU for the Sys > Proc sub-tab, mirroring
# textual-config's App/Logic/processes.py.
import json
import subprocess

r = subprocess.run(
    ["ps", "-eo", "pid,user,%cpu,%mem,comm", "--sort=-%cpu", "--no-headers"],
    capture_output=True, text=True,
)
processes = []
for line in r.stdout.splitlines()[:40]:
    parts = line.split(None, 4)
    if len(parts) < 5:
        continue
    processes.append({
        "pid": int(parts[0]),
        "user": parts[1][:12],
        "cpu": float(parts[2]),
        "mem": float(parts[3]),
        "name": parts[4].strip()[:12],
    })

print(json.dumps(processes))
