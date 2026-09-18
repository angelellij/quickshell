#!/usr/bin/env python3
# Emits the system/hardware blocks of Sys > Info: hostname, OS, CPU model,
# GPU, disks, etc. None of this changes without a reboot, so it's polled on
# its own (much slower) interval instead of alongside cpu%/ram%/network
# speed in sysinfo.py, which used to re-run lspci/lsblk every 3 seconds
# for data that never changes during a session.
import json
import os
import platform
import socket
import subprocess
from pathlib import Path


def get_os():
    try:
        for line in Path("/etc/os-release").read_text().splitlines():
            if line.startswith("PRETTY_NAME="):
                return line.split("=", 1)[1].strip('"')
    except Exception:
        pass
    return f"{platform.system()} {platform.release()}"


def get_desktop():
    for var in ("XDG_CURRENT_DESKTOP", "DESKTOP_SESSION", "GDMSESSION"):
        val = os.environ.get(var, "")
        if val:
            return val
    return "Unknown"


def get_uptime():
    try:
        seconds = float(Path("/proc/uptime").read_text().split()[0])
        d, h, m = int(seconds // 86400), int((seconds % 86400) // 3600), int((seconds % 3600) // 60)
        parts = ([f"{d}d"] if d else []) + ([f"{h}h"] if h else []) + [f"{m}m"]
        return " ".join(parts)
    except Exception:
        return "Unknown"


def get_cpu_model():
    try:
        for line in Path("/proc/cpuinfo").read_text().splitlines():
            if line.startswith("model name"):
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return "Unknown"


def get_cpu_cores():
    try:
        physical, logical = set(), 0
        for line in Path("/proc/cpuinfo").read_text().splitlines():
            if line.startswith("physical id"):
                physical.add(line.split(":")[1].strip())
            elif line.startswith("processor"):
                logical += 1
        return f"{len(physical) or 1} physical / {logical} logical"
    except Exception:
        return str(os.cpu_count() or "Unknown")


def get_gpu():
    try:
        out = subprocess.run(["lspci"], capture_output=True, text=True).stdout
        for line in out.splitlines():
            if any(k in line for k in ("VGA", "3D controller", "Display")):
                return line.split(":", 2)[-1].strip()
    except Exception:
        pass
    return "Unknown"


def get_disks():
    try:
        out = subprocess.run(["lsblk", "-dno", "NAME,MODEL,SIZE"], capture_output=True, text=True).stdout
        results = []
        for line in out.strip().splitlines():
            parts = line.split(None, 2)
            if not parts or not any(parts[0].startswith(p) for p in ("sd", "nvme", "vd", "hd", "mmcblk")):
                continue
            model = parts[1].strip() if len(parts) > 1 else parts[0]
            size = parts[2].strip() if len(parts) > 2 else ""
            results.append(f"{model}  {size}".strip())
        return results or ["Unknown"]
    except Exception:
        return ["Unknown"]


def get_ram_total():
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith("MemTotal:"):
                return f"{int(line.split()[1]) / 1024**2:.1f} GB"
    except Exception:
        pass
    return "Unknown"


print(json.dumps({
    "system": {
        "hostname": socket.gethostname(),
        "os": get_os(),
        "kernel": platform.release(),
        "arch": platform.machine(),
        "desktop": get_desktop(),
        "uptime": get_uptime(),
    },
    "hardware": {
        "cpu": get_cpu_model(),
        "cores": get_cpu_cores(),
        "gpu": get_gpu(),
        "ram": get_ram_total(),
        "disks": get_disks(),
    },
}))
