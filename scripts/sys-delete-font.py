#!/usr/bin/env python3
# Removes a font file from ~/.local/share/fonts and refreshes the cache.
import subprocess
import sys
from pathlib import Path

FONTS_DIR = Path.home() / ".local/share/fonts"

Path(sys.argv[1]).unlink(missing_ok=True)
subprocess.run(["fc-cache", "-f", str(FONTS_DIR)], capture_output=True)
