#!/bin/bash
# Emits a JSON array of active playback streams
# ([{"id":..., "name":..., "volume":...}, ...]) for per-app volume sliders,
# reading pactl's sink-input list (works against PipeWire via pipewire-pulse).

pactl -f json list sink-inputs | python3 -c '
import json, sys

data = json.load(sys.stdin)
out = []
for s in data:
    name = s.get("properties", {}).get("application.name", "?")
    vol = s.get("volume", {})
    pct = 0
    if vol:
        first = next(iter(vol.values()))
        pct = int(first.get("value_percent", "0%").rstrip("%"))
    out.append({"id": s["index"], "name": name, "volume": pct})
print(json.dumps(out))
'
