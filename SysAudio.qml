import QtQuick
import QtQuick.Layouts
import Quickshell

// Audio: dispositivos de salida y entrada.
SysTab {
    id: root
    tabId: "audio"

    PollingProcess { id: audioPoll; active: root.polling; interval: 5000; fallback: ({sinks: [], sources: []})
        command: Sh.cmd("sys-audio-info.py") }

    SectionBox {
        title: "Output Devices"
        Repeater {
            model: audioPoll.json.sinks || []
            delegate: ToggleButton {
                Layout.fillWidth: true
                text: modelData.description
                active: modelData.is_default
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Quickshell.execDetached(["pactl", "set-default-sink", modelData.name])
            }
        }
    }

    SectionBox {
        title: "Input Devices"
        Repeater {
            model: audioPoll.json.sources || []
            delegate: ToggleButton {
                Layout.fillWidth: true
                text: modelData.description
                active: modelData.is_default
                plain: true
                strikeInactive: true
                accentActive: true
                onClicked: Quickshell.execDetached(["pactl", "set-default-source", modelData.name])
            }
        }
    }
}
