#!/usr/bin/env python3
# Deletes one /etc/apt/sources.list.d/* file (needs sudo). The QML side
# never calls this for /etc/apt/sources.list itself - that one isn't
# individually deletable, same rule as textual-config's repos.py.
import subprocess
import sys

subprocess.run(["sudo", "rm", sys.argv[1]])
