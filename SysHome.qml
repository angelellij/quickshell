import QtQuick
import QtQuick.Layouts
import Quickshell

// Home: audio, WiFi, Bluetooth, conexiones, powersave y sistema.
SysTab {
    id: root
    tabId: "home"

    PollingProcess { id: streamsPoll; active: root.polling; interval: 1000; fallback: []
        command: Sh.cmd("list-audio-streams.sh") }
    PollingProcess { id: netPoll; active: root.polling; interval: 5000; fallback: ({wifi: [], connections: []})
        command: Sh.cmd("sys-net-info.py") }
    PollingProcess { id: btPoll; active: root.polling; interval: 5000; fallback: ({power: false, devices: []})
        command: Sh.cmd("sys-bt-info.py") }
    PollingProcess { id: wifiPoll; active: root.polling; interval: 3000
        command: ["nmcli", "radio", "wifi"] }
    PollingProcess { id: profilePoll; active: root.polling; interval: 3000
        command: Sh.cmd("get-power-profile.sh") }

    SectionBox {
        title: "Audio"
        SliderRow {
            Layout.fillWidth: true
            visible: Features.brightness
            label: "Brillo"
            min: 1
            valueNum: Stats.brilloNum
            onChanged: (value) => Quickshell.execDetached(["bash", "-c", "brightnessctl set " + Math.round(value) + "% -q"])
        }
        SliderRow {
            Layout.fillWidth: true
            label: "Volumen"
            min: 0
            max: 200
            valueNum: Stats.volumenNum
            onChanged: (value) => Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(value) + "%"])
        }
        SliderRow {
            Layout.fillWidth: true
            label: "Mic"
            min: 0
            max: 200
            valueNum: Stats.micVolNum
            onChanged: (value) => Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(value) + "%"])
        }
        Repeater {
            model: streamsPoll.json
            delegate: SliderRow {
                Layout.fillWidth: true
                label: modelData.name
                min: 0
                valueNum: modelData.volume
                onChanged: (value) => Quickshell.execDetached(["pactl", "set-sink-input-volume", String(modelData.id), Math.round(value) + "%"])
            }
        }
    }

    SectionBox {
        title: "WiFi"
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ToggleButton {
                text: "ON"
                active: wifiPoll.text === "enabled"
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", "on"])
            }
            Rectangle { implicitWidth: 1; implicitHeight: 13; color: Theme.border }
            ToggleButton {
                text: "OFF"
                active: wifiPoll.text !== "enabled"
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", "off"])
            }
            Item { Layout.fillWidth: true }
        }
        ActionButton {
            label: "Scan"
            onClicked: Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"])
        }
        Repeater {
            model: netPoll.json.wifi || []
            delegate: ToggleButton {
                Layout.fillWidth: true
                text: modelData.ssid + " (" + modelData.signal + "%, " + modelData.security + ")"
                active: modelData.active
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Sh.terminal("nmcli --ask device wifi connect \"$1\"", [modelData.ssid])
            }
        }
    }

    SectionBox {
        title: "Net Connections"
        Repeater {
            model: netPoll.json.connections || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.name + " (" + modelData.type + ", " + modelData.state + ")"
                    elide: Text.ElideRight
                }
                DeleteButton {
                    onClicked: Quickshell.execDetached(["nmcli", "con", "delete", modelData.name])
                }
            }
        }
    }

    SectionBox {
        title: "Bluetooth"
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ToggleButton {
                text: "ON"
                active: btPoll.json.power
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Sh.run("sys-bt-power.py", ["on"])
            }
            Rectangle { implicitWidth: 1; implicitHeight: 13; color: Theme.border }
            ToggleButton {
                text: "OFF"
                active: !btPoll.json.power
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Sh.run("sys-bt-power.py", ["off"])
            }
            Item { Layout.fillWidth: true }
        }
        ActionButton {
            label: "Scan (10s)"
            onClicked: Sh.terminal("bluetoothctl --timeout 10 scan on")
        }
        Repeater {
            model: btPoll.json.devices || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleButton {
                    Layout.fillWidth: true
                    text: modelData.name + (modelData.paired ? "" : " (sin emparejar)")
                    active: modelData.connected
                    plain: true
                    strikeInactive: true
                    accentActive: true
                    onClicked: {
                        var action = !modelData.paired ? "pair" : (modelData.connected ? "disconnect" : "connect")
                        Sh.run("sys-bt-action.py", [modelData.controller, modelData.mac, action])
                    }
                }
                DeleteButton {
                    onClicked: Sh.run("sys-bt-action.py", [modelData.controller, modelData.mac, "remove"])
                }
            }
        }
    }

    SectionBox {
        title: "Powersave"
        TagRow {
            Layout.fillWidth: true
            items: [
                { label: "Eco",    active: profilePoll.text === "eco",    onClicked: () => Sh.run("set-power-profile.sh", ["eco"]) },
                { label: "Bal",    active: profilePoll.text === "bal",    onClicked: () => Sh.run("set-power-profile.sh", ["bal"]) },
                { label: "Full",   active: profilePoll.text === "full",   onClicked: () => Sh.run("set-power-profile.sh", ["full"]) },
                { label: "Xtreme", active: profilePoll.text === "xtreme", onClicked: () => Sh.run("set-power-profile.sh", ["xtreme"]) }
            ]
        }
    }

    SectionBox {
        title: "System"
        TagRow {
            Layout.fillWidth: true
            items: [
                { label: "Shutdown",  active: false, onClicked: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
                { label: "Reiniciar", active: false, onClicked: () => Quickshell.execDetached(["systemctl", "reboot"]) },
                { label: "Logout",    active: false, onClicked: () => Quickshell.execDetached(["niri", "msg", "action", "quit"]) }
            ]
        }
    }
}
