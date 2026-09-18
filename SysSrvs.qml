import QtQuick
import QtQuick.Layouts
import Quickshell

// Srvs: cron jobs y servicios de systemd.
SysTab {
    id: root
    tabId: "srvs"

    PollingProcess { id: srvsPoll; active: root.polling; interval: 5000; fallback: ({services: [], crons: []})
        command: Sh.cmd("sys-srvs-info.py") }

    SectionBox {
        title: "Cron Jobs"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Schedule (ej: 0 3 * * *): ' sched; read -p 'Comando: ' cmd; \"$S/sys-cron-add.py\" \"$sched\" \"$cmd\"")
        }
        Repeater {
            model: srvsPoll.json.crons || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.schedule + "  " + modelData.command
                    elide: Text.ElideRight
                }
                DeleteButton {
                    onClicked: Sh.run("sys-cron-delete.py", [String(modelData.line_num)])
                }
            }
        }
    }

    SectionBox {
        title: "Services"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Nombre: ' name; path=$(\"$S/sys-create-service.py\" \"$name\") && pkexec nvim \"$path\"")
        }
        Repeater {
            model: srvsPoll.json.services || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleButton {
                    Layout.fillWidth: true
                    text: modelData.name
                    active: modelData.active === "active"
                    plain: true
                    accentActive: true
                    onClicked: Quickshell.execDetached(["pkexec", "systemctl",
                        modelData.active === "active" ? "stop" : "start", modelData.unit])
                }
                DeleteButton {
                    visible: modelData.deletable === true
                    onClicked: Quickshell.execDetached(["pkexec", "bash", "-c",
                        "rm \"$1\" && systemctl daemon-reload", "_", modelData.path])
                }
            }
        }
    }
}
