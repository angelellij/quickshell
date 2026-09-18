#!/usr/bin/env python3
# Emits output/input device lists for the Sys > Audio sub-tab (volume
# sliders already live in Home - this is just default-device selection),
# mirroring textual-config's App/Logic/audio.py get_sinks/get_sources.
import json
import subprocess


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return r.stdout
    except Exception:
        return ""


def parse_devices(text, default):
    devices, current = [], {}
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("Sink #") or line.startswith("Source #"):
            if current.get("name"):
                devices.append(current)
            current = {}
        elif line.startswith("Name:"):
            name = line.split(":", 1)[1].strip()
            current["name"] = name
            current["is_default"] = name == default
        elif line.startswith("Description:"):
            current["description"] = line.split(":", 1)[1].strip()
    if current.get("name"):
        devices.append(current)
    return devices


def get_sinks():
    default = run(["pactl", "get-default-sink"]).strip()
    return parse_devices(run(["pactl", "list", "sinks"]), default)


def get_sources():
    default = run(["pactl", "get-default-source"]).strip()
    devs = parse_devices(run(["pactl", "list", "sources"]), default)
    return [d for d in devs if not d["name"].endswith(".monitor")]


print(json.dumps({"sinks": get_sinks(), "sources": get_sources()}))
