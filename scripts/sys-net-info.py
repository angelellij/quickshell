#!/usr/bin/env python3
# Emits WiFi networks + saved connections for the Sys > Net sub-tab, mirroring
# textual-config's App/Logic/{wifi,ip_config}.py (kept standalone here since
# that's a separate application, not a dependency).
import json
import subprocess


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return r.returncode, r.stdout
    except Exception:
        return 1, ""


def split_nmcli(line, n):
    # nmcli -t escapes ':' inside fields as '\:'
    parts, cur, esc = [], "", False
    for ch in line:
        if esc:
            cur += ch
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    parts.append(cur)
    return parts[:n] + [""] * (n - len(parts))


def get_wifi_networks():
    code, out = run(["nmcli", "--escape", "yes", "-t", "-f", "SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list"])
    if code != 0:
        return []
    networks, seen = [], set()
    for line in out.splitlines():
        ssid, signal, security, active = split_nmcli(line, 4)
        if not ssid or ssid in seen:
            continue
        seen.add(ssid)
        networks.append({
            "ssid": ssid,
            "signal": int(signal) if signal.isdigit() else 0,
            "security": security if security and security != "--" else "Open",
            "active": active.lower() == "yes",
        })
    return sorted(networks, key=lambda x: -x["signal"])


def get_connections():
    code, out = run(["nmcli", "--escape", "yes", "-t", "-f", "NAME,TYPE,STATE", "con", "show"])
    if code != 0:
        return []
    conns = []
    for line in out.splitlines():
        name, type_, state = split_nmcli(line, 3)
        if not name:
            continue
        short_type = type_.replace("802-11-wireless", "wifi").replace("802-3-ethernet", "ethernet")
        conns.append({"name": name, "type": short_type, "state": state})
    return conns


print(json.dumps({"wifi": get_wifi_networks(), "connections": get_connections()}))
