#!/usr/bin/env python3
# Removes one entry (by its index among non-comment/non-blank lines,
# matching sys-srvs-info.py's line_num) from the user's crontab.
import subprocess
import sys

target = int(sys.argv[1])
r = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
lines = r.stdout.splitlines() if r.returncode == 0 else []

real_idx, keep = 0, []
for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        keep.append(line)
        continue
    if real_idx != target:
        keep.append(line)
    real_idx += 1

subprocess.run(["crontab", "-"], input="\n".join(keep) + "\n", capture_output=True, text=True)
