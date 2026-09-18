#!/bin/bash
# Toggles the focused window's column between 50% and 100% width.
# Uses set-column-width, not real fullscreen: true fullscreen covers the
# Top/Overlay layer-shell layers on some setups (wvkbd, launchers), so we
# avoid it here entirely.

OUT_WIDTH=$(niri msg --json outputs | python3 -c "import json,sys; d=json.load(sys.stdin); print(list(d.values())[0]['logical']['width'])")
TILE_WIDTH=$(niri msg --json focused-window | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['layout']['tile_size'][0])")

IS_MAXIMIZED=$(python3 -c "print(1 if $TILE_WIDTH > 0.9 * $OUT_WIDTH else 0)")

if [ "$IS_MAXIMIZED" = "1" ]; then
    niri msg action set-column-width "50%"
else
    niri msg action set-column-width "100%"
fi
