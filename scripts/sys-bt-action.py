#!/usr/bin/env python3
# Runs a bluetoothctl action (connect/disconnect/pair/remove) against a
# specific device, selecting its own controller first - see sys-bt-info.py
# for why that matters on multi-controller machines.
import subprocess
import sys

controller, mac, action = sys.argv[1], sys.argv[2], sys.argv[3]
subprocess.run(["bluetoothctl"], capture_output=True, text=True,
                input=f"select {controller}\n{action} {mac}\nquit\n")
