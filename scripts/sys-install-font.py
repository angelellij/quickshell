#!/usr/bin/env python3
# Copies a font file into ~/.local/share/fonts and refreshes the cache.
import shutil
import subprocess
import sys
from pathlib import Path

FONTS_DIR = Path.home() / ".local/share/fonts"
FONT_EXTS = {".ttf", ".otf", ".woff", ".woff2"}

src = Path(sys.argv[1])
if not src.exists():
    print(f"No existe: {src}", file=sys.stderr)
    sys.exit(1)
if src.suffix.lower() not in FONT_EXTS:
    print("Formato no soportado (usa TTF, OTF, WOFF o WOFF2)", file=sys.stderr)
    sys.exit(1)

FONTS_DIR.mkdir(parents=True, exist_ok=True)
shutil.copy2(src, FONTS_DIR / src.name)
subprocess.run(["fc-cache", "-f", str(FONTS_DIR)], capture_output=True)
