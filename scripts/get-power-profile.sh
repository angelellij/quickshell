#!/bin/bash
# Prints which unified power profile (eco/bal/full/xtreme) matches the
# current power-profile + CPU governor + ASPM policy + turbo + kbd backlight +
# GPU max freq + refresh rate combo, or nothing if changed independently.

PROFILE=$(cat /sys/firmware/acpi/platform_profile)
GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
ASPM=$(sed 's/.*\[\(.*\)\].*/\1/' /sys/module/pcie_aspm/parameters/policy)
TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
KBD=$(cat /sys/class/leds/dell::kbd_backlight/brightness)
GPU=$(cat /sys/class/drm/card0/gt_max_freq_mhz)
HZ=$(niri msg --json outputs | python3 -c "import json,sys; d=json.load(sys.stdin); m=d['eDP-1']['modes'][d['eDP-1']['current_mode']]; print(round(m['refresh_rate']/1000))")

if [[ "$PROFILE" == "quiet" && "$GOVERNOR" == "powersave" && "$ASPM" == "powersupersave" && "$TURBO" == "1" && "$KBD" == "0" && "$GPU" == "300" && "$HZ" == "48" ]]; then
    echo "eco"
elif [[ "$PROFILE" == "balanced" && "$GOVERNOR" == "powersave" && "$ASPM" == "powersave" && "$TURBO" == "1" && "$KBD" == "0" && "$GPU" == "650" && "$HZ" == "48" ]]; then
    echo "bal"
elif [[ "$PROFILE" == "performance" && "$GOVERNOR" == "powersave" && "$ASPM" == "performance" && "$TURBO" == "0" && "$KBD" != "0" && "$GPU" != "300" && "$GPU" != "650" && "$HZ" == "60" ]]; then
    echo "full"
elif [[ "$PROFILE" == "performance" && "$GOVERNOR" == "performance" && "$ASPM" == "performance" && "$TURBO" == "0" && "$KBD" != "0" && "$GPU" != "300" && "$GPU" != "650" && "$HZ" == "60" ]]; then
    echo "xtreme"
fi
