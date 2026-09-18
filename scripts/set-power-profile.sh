#!/bin/bash
# Unified power profile: sets ACPI platform_profile + CPU governor + PCIe ASPM
# policy + screen refresh rate together, instead of controlling them
# independently.
# (Uses /sys/firmware/acpi/platform_profile directly since power-profiles-daemon
# was removed when tlp was installed — the two packages conflict on Debian.)
#
#   Eco     -> quiet       + cpu powersave   + aspm powersupersave + turbo off + kbd off + gpu 300MHz  + 48Hz
#   Bal     -> balanced    + cpu powersave   + aspm powersave      + turbo off + kbd off + gpu 650MHz  + 48Hz
#   Full    -> performance + cpu powersave   + aspm performance    + turbo on  + kbd on  + gpu 1100MHz + 60Hz
#   Xtreme  -> performance + cpu performance + aspm performance    + turbo on  + kbd on  + gpu 1100MHz + 60Hz

OUTPUT="eDP-1"
MODE_60="1920x1280@59.959"
MODE_48="1920x1280@47.967"
KBD_LED="/sys/class/leds/dell::kbd_backlight/brightness"
KBD_MAX=$(cat "/sys/class/leds/dell::kbd_backlight/max_brightness")
GPU_MAX="/sys/class/drm/card0/gt_max_freq_mhz"
GPU_RP0=$(cat /sys/class/drm/card0/gt_RP0_freq_mhz)

set_platform_profile() {
    echo "$1" | sudo tee /sys/firmware/acpi/platform_profile >/dev/null
}

set_aspm_policy() {
    echo "$1" | sudo tee /sys/module/pcie_aspm/parameters/policy >/dev/null
}

set_turbo() {
    echo "$1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
}

set_kbd_backlight() {
    echo "$1" > "$KBD_LED"
}

set_gpu_max_freq() {
    echo "$1" | sudo tee "$GPU_MAX" >/dev/null
}

case "$1" in
    eco)
        set_platform_profile quiet
        sudo cpupower frequency-set -g powersave >/dev/null
        set_aspm_policy powersupersave
        set_turbo 1
        set_kbd_backlight 0
        set_gpu_max_freq 300
        niri msg output "$OUTPUT" mode "$MODE_48"
        ;;
    bal)
        set_platform_profile balanced
        sudo cpupower frequency-set -g powersave >/dev/null
        set_aspm_policy powersave
        set_turbo 1
        set_kbd_backlight 0
        set_gpu_max_freq 650
        niri msg output "$OUTPUT" mode "$MODE_48"
        ;;
    full)
        set_platform_profile performance
        sudo cpupower frequency-set -g powersave >/dev/null
        set_aspm_policy performance
        set_turbo 0
        set_kbd_backlight "$KBD_MAX"
        set_gpu_max_freq "$GPU_RP0"
        niri msg output "$OUTPUT" mode "$MODE_60"
        ;;
    xtreme)
        set_platform_profile performance
        sudo cpupower frequency-set -g performance >/dev/null
        set_aspm_policy performance
        set_turbo 0
        set_kbd_backlight "$KBD_MAX"
        set_gpu_max_freq "$GPU_RP0"
        niri msg output "$OUTPUT" mode "$MODE_60"
        ;;
    *)
        echo "Uso: $0 {eco|bal|full|xtreme}" >&2
        exit 1
        ;;
esac
