#!/usr/bin/env python3
# Powers all bluetooth controllers on/off together (there are 2 on this
# machine, and bluetoothctl's plain "power on/off" only ever hits whichever
# one it picks as its per-invocation default).
import re
import subprocess
import sys

state = sys.argv[1]  # "on" or "off"

r = subprocess.run(["bluetoothctl"], capture_output=True, text=True, input="list\nquit\n")
controllers = re.findall(r"Controller\s+([0-9A-Fa-f:]{17})", r.stdout)

cmds = "".join(f"select {c}\npower {state}\n" for c in controllers) + "quit\n"
subprocess.run(["bluetoothctl"], capture_output=True, text=True, input=cmds)
