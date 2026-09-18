#!/usr/bin/env python3
# Appends one entry to the user's crontab.
import subprocess
import sys

schedule, command = sys.argv[1], sys.argv[2]
r = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
lines = r.stdout.splitlines() if r.returncode == 0 else []
lines.append(f"{schedule} {command}")
subprocess.run(["crontab", "-"], input="\n".join(lines) + "\n", capture_output=True, text=True)
