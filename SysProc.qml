import QtQuick
import QtQuick.Layouts
import Quickshell

// Proc: procesos por uso de CPU, con opcion de matarlos.
SysTab {
    id: root
    tabId: "proc"

    PollingProcess { id: procPoll; active: root.polling; interval: 3000; fallback: []
        command: Sh.cmd("sys-proc-info.py") }

    SectionBox {
        title: "Processes"
        Repeater {
            model: procPoll.json || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.preferredWidth: 84
                    text: modelData.name
                    elide: Text.ElideRight
                }
                ThemedText {
                    Layout.preferredWidth: 60
                    text: modelData.user
                    elide: Text.ElideRight
                    opacity: Theme.dim
                }
                ThemedText {
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                    text: modelData.cpu + "%"
                }
                ThemedText {
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                    text: modelData.mem + "%"
                }
                Item { Layout.fillWidth: true }
                DeleteButton {
                    onClicked: Quickshell.execDetached(["kill", String(modelData.pid)])
                }
            }
        }
    }
}
