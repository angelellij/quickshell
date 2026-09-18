#!/usr/bin/env python3
# Emits a JSON array of upgradable package names, for the Sys > System Info
# "Updates" box. Separate from sysinfo.py because checking for updates is
# slow (apt hits the package cache) and shouldn't run on a short poll.
import json
import os
import subprocess


def get_updates():
    try:
        r = subprocess.run(["checkupdates"], capture_output=True, text=True, timeout=60)
        if r.returncode == 0:
            return [l.strip() for l in r.stdout.strip().splitlines() if l.strip()]
        if r.returncode == 2:
            return []
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    try:
        r = subprocess.run(
            ["apt", "list", "--upgradable", "-qq"],
            capture_output=True, text=True, timeout=60,
            env={**os.environ, "DEBIAN_FRONTEND": "noninteractive"},
        )
        if r.returncode == 0:
            return [l.split("/")[0] for l in r.stdout.splitlines() if "/" in l]
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    try:
        r = subprocess.run(["dnf", "check-update", "-q"], capture_output=True, text=True, timeout=60)
        if r.returncode in (0, 100):
            return [l.split()[0] for l in r.stdout.strip().splitlines() if l and "." in l.split()[0]]
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return []


print(json.dumps(get_updates()))
