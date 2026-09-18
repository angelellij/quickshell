#!/usr/bin/env python3
# Emits systemd services + user crontab entries for the Sys > Srvs sub-tab,
# mirroring textual-config's App/Logic/{services,cron}.py (kept standalone
# here since that's a separate application, not a dependency).
import json
import subprocess
from pathlib import Path

SERVICE_DIR = Path("/etc/systemd/system")


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return r.returncode, r.stdout
    except Exception:
        return 1, ""


def get_services():
    _, out_files = run(["systemctl", "list-unit-files", "--type=service", "--no-pager", "--no-legend"])
    enabled_map = {}
    for line in out_files.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            enabled_map[parts[0]] = parts[1]

    _, out_units = run(["systemctl", "list-units", "--type=service", "--all", "--no-pager", "--no-legend"])
    active_map = {}
    for line in out_units.splitlines():
        line = line.strip().lstrip("●○").strip()
        parts = line.split()
        if len(parts) >= 3 and parts[0].endswith(".service"):
            active_map[parts[0]] = parts[2]

    services = []
    for unit, enabled in enabled_map.items():
        if enabled in ("generated", "transient", "bad"):
            continue
        services.append({
            "name": unit.removesuffix(".service"),
            "unit": unit,
            "active": active_map.get(unit, "inactive"),
            "enabled": enabled,
            "path": str(SERVICE_DIR / unit),
            "deletable": (SERVICE_DIR / unit).exists(),
        })
    return sorted(services, key=lambda s: s["name"])


def get_user_crons():
    code, out = run(["crontab", "-l"])
    if code != 0:
        return []
    entries = []
    line_num = 0
    for line in out.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("@"):
            parts = stripped.split(None, 1)
            schedule, command = parts[0], (parts[1] if len(parts) > 1 else "")
        else:
            parts = stripped.split(None, 5)
            if len(parts) < 6:
                line_num += 1
                continue
            schedule, command = " ".join(parts[:5]), parts[5]
        entries.append({"line_num": line_num, "schedule": schedule, "command": command})
        line_num += 1
    return entries


print(json.dumps({"services": get_services(), "crons": get_user_crons()}))
