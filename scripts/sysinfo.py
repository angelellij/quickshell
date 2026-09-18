#!/usr/bin/env python3
# Emits the "usage" block of Sys > Info (cpu%, ram%, network speed, etc) -
# the genuinely fast-changing stuff. Static hardware info (hostname, CPU
# model, GPU, disks) lives in sysinfo-static.py, polled far less often.
import json
import shutil
import time
from pathlib import Path


def meminfo():
    info = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            info[k.strip()] = int(v.split()[0])
    return info


def get_ram():
    try:
        info = meminfo()
        total, used = info["MemTotal"], info["MemTotal"] - info["MemAvailable"]
        return f"{used / 1024**2:.1f} / {total / 1024**2:.1f} GB ({used * 100 // total}%)"
    except Exception:
        return "Unknown"


def get_swap():
    try:
        info = meminfo()
        total = info.get("SwapTotal", 0)
        if total == 0:
            return "N/A"
        used = total - info.get("SwapFree", 0)
        return f"{used / 1024**2:.1f} / {total / 1024**2:.1f} GB ({used * 100 // total}%)"
    except Exception:
        return "Unknown"


def get_disk():
    try:
        u = shutil.disk_usage("/")
        return f"{u.used / 1024**3:.0f} / {u.total / 1024**3:.0f} GB ({u.used * 100 // u.total}%)"
    except Exception:
        return "Unknown"


def get_network():
    try:
        import subprocess
        out = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True).stdout
        parts = out.split()
        iface = parts[parts.index("dev") + 1]
        ip_out = subprocess.run(["ip", "-4", "addr", "show", iface], capture_output=True, text=True).stdout
        for line in ip_out.splitlines():
            if "inet " in line:
                ip = line.strip().split()[1].split("/")[0]
                return f"{iface}  {ip}"
    except Exception:
        pass
    return "No connection"


def get_cpu_temp():
    try:
        zones = sorted(Path("/sys/class/thermal").glob("thermal_zone*"))
        for zone in zones:
            t = (zone / "type").read_text().strip().lower()
            if any(k in t for k in ("cpu", "x86_pkg", "acpitz", "coretemp")):
                return f"{int((zone / 'temp').read_text()) / 1000:.1f} C"
        if zones:
            return f"{int((zones[0] / 'temp').read_text()) / 1000:.1f} C"
    except Exception:
        pass
    return "N/A"


def get_load_avg():
    try:
        return "  ".join(Path("/proc/loadavg").read_text().split()[:3])
    except Exception:
        return "Unknown"


def get_process_count():
    try:
        return sum(1 for p in Path("/proc").iterdir() if p.name.isdigit())
    except Exception:
        return 0


def read_cpu_ticks():
    fields = list(map(int, Path("/proc/stat").read_text().splitlines()[0].split()[1:]))
    idle = fields[3] + (fields[4] if len(fields) > 4 else 0)
    return idle, sum(fields)


def read_net_bytes():
    rx = tx = 0
    for line in Path("/proc/net/dev").read_text().splitlines()[2:]:
        parts = line.split()
        if parts[0].rstrip(":") == "lo":
            continue
        rx += int(parts[1])
        tx += int(parts[9])
    return rx, tx


def fmt_speed(bps):
    if bps >= 1024 ** 2:
        return f"{bps / 1024 ** 2:.1f} MB/s"
    if bps >= 1024:
        return f"{bps / 1024:.1f} KB/s"
    return f"{bps:.0f} B/s"


idle1, total1 = read_cpu_ticks()
rx1, tx1 = read_net_bytes()
time.sleep(0.5)
idle2, total2 = read_cpu_ticks()
rx2, tx2 = read_net_bytes()

dt = total2 - total1
cpu_pct = round((1 - (idle2 - idle1) / dt) * 100) if dt > 0 else 0

print(json.dumps({
    "cpu_pct": f"{cpu_pct}%",
    "cpu_temp": get_cpu_temp(),
    "load_avg": get_load_avg(),
    "processes": get_process_count(),
    "ram": get_ram(),
    "swap": get_swap(),
    "disk": get_disk(),
    "network": get_network(),
    "rx": fmt_speed((rx2 - rx1) / 0.5),
    "tx": fmt_speed((tx2 - tx1) / 0.5),
}))
