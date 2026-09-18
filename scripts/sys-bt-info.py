#!/usr/bin/env python3
# Emits bluetooth power state + known devices for the Sys > BT sub-tab.
# This machine has TWO bluetooth controllers, and bluetoothctl's implicit
# "default controller" (picked per-invocation, not persisted) isn't
# necessarily the one an actual device is paired to - so every device is
# queried against ITS OWN controller instead of relying on any default.
import json
import re
import subprocess


def run(input_text, timeout=15):
    try:
        r = subprocess.run(["bluetoothctl"], capture_output=True, text=True, timeout=timeout, input=input_text)
        return r.stdout
    except Exception:
        return ""


def get_controllers():
    return re.findall(r"Controller\s+([0-9A-Fa-f:]{17})", run("list\nquit\n"))


def get_power_and_devices(ctrl):
    out = run(f"select {ctrl}\nshow\ndevices\nquit\n")
    powered = "Powered: yes" in out
    devices = re.findall(r"Device\s+([0-9A-Fa-f:]{17})\s+(.+)", out)
    return powered, devices


def get_infos(ctrl, macs):
    if not macs:
        return {}
    cmds = f"select {ctrl}\n" + "".join(f"info {m}\n" for m in macs) + "quit\n"
    out = run(cmds)
    infos = {}
    for block in re.split(r"(?=Device [0-9A-Fa-f:]{17} \()", out):
        m = re.match(r"Device ([0-9A-Fa-f:]{17})", block)
        if not m:
            continue
        infos[m.group(1)] = {
            "connected": "Connected: yes" in block,
            "paired": "Paired: yes" in block,
        }
    return infos


controllers = get_controllers()
overall_power = False
devices = []
seen = set()

for ctrl in controllers:
    powered, dev_list = get_power_and_devices(ctrl)
    overall_power = overall_power or powered
    macs = [mac for mac, _ in dev_list if mac not in seen]
    infos = get_infos(ctrl, macs)
    for mac, name in dev_list:
        if mac in seen:
            continue
        seen.add(mac)
        info = infos.get(mac, {"connected": False, "paired": False})
        devices.append({"mac": mac, "name": name.strip(), "controller": ctrl, **info})

print(json.dumps({"power": overall_power, "devices": devices}))
