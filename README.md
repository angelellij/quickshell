# quickshell

Sidebar, apps/system panel and notifications for [niri](https://github.com/YaLTeR/niri), built with [Quickshell](https://quickshell.org) (QML).

- **Toolbar:** clock, CPU, GPU, RAM, volume and mic always in view.
- **Panel (`Mod+Space`):** Apps, Code, Cmds, Sys and AOE2 tabs.
- **Notifications:** replace dunst.

## Requirements

**Required**

| What | What for |
|---|---|
| [quickshell](https://quickshell.org) 0.3 or newer | Everything (on Debian 13 it comes from `trixie-backports`) |
| [niri](https://github.com/YaLTeR/niri) | Compositor. The shortcut and several actions use `niri msg` |
| PipeWire (`wpctl`, `pactl`, `pw-play`) | Volume, mic and notification sound |
| `python3` | Most of the scripts in `scripts/` |
| `alacritty` and `nvim` | Terminal and editor for interactive actions (change them in `Sh.qml`) |
| `xdg-utils` | Opening links and default apps |
| JetBrains Mono font | Typeface for the whole interface |

**For the Sys tab** (depending on the sub-tab): NetworkManager (`nmcli`), BlueZ (`bluetoothctl`), `pkexec` (polkit), `ufw`, systemd (`systemctl`, `timedatectl`, `localectl`), `cron`, `pciutils`, `apt`/`dpkg` (**Debian and derivatives only**) and optionally `brightnessctl`.

**Optional**
- Steam, for the button that opens AOE2 DE.
- `textual-config` (a custom configuration tool): the Cmds tab lists `~/.config/textual-config/commands`, and Sys → Other saves Editor and Theme there.
- Power profiles (Sys → Home): only with an Intel GPU and ACPI `platform_profile`.

## Per-machine configuration

`Features.qml` reads `features.default.json` and, if present, `features.<hostname>.json` (the hostname comes from `/etc/hostname`) containing only that machine's differences. It lets you turn `gpu`, `battery`, `brightness`, `virtualKeyboard`, `fullscreenToggle`, `screenshot`, `aoe2Panel` and `aoe2Launcher` on or off.

## AOE2 tab

Lists the followed players (current and all-time peak Elo in 1v1 Random Map) and the ongoing matches they are playing. It refreshes when the tab is opened if more than 5 minutes have passed, and every hour in the background.

Players are edited with the "Editar jugadores seguidos" button, which opens `~/.config/quickshell/aoe2-players.csv`: one line per player as `id group`. The group name may contain spaces and the same id may appear in several groups.

```
1324391 My group
3123520 My group
3123520 Another group
```

Data comes from `aoe-api.worldsedgelink.com` and `data.aoe2companion.com`.

## Made with AI

This project was made with AI (Claude, by Anthropic).
