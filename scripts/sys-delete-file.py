#!/usr/bin/env python3
# Deletes a user-owned file (Commands script, Startup .desktop entry).
import sys
from pathlib import Path

Path(sys.argv[1]).unlink(missing_ok=True)
