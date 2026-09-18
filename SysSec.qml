import QtQuick
import QtQuick.Layouts
import Quickshell

// Sec: firewall (ufw) y usuarios.
SysTab {
    id: root
    tabId: "sec"

    PollingProcess { id: secPoll; active: root.polling; interval: 5000; fallback: ({firewall: {}, users: []})
        command: Sh.cmd("sys-sec-info.py") }

    SectionBox {
        title: "Firewall"
        ToggleButton {
            Layout.fillWidth: true
            text: secPoll.json.firewall.available ? "ufw" : "ufw (no instalado)"
            active: secPoll.json.firewall.active === true
            plain: true
            accentActive: true
            onClicked: Quickshell.execDetached(["pkexec", "ufw", "--force",
                secPoll.json.firewall.active ? "disable" : "enable"])
        }
        ActionButton {
            label: "Add rule"
            onClicked: Sh.terminal("read -p 'Regla (ej: allow 22): ' rule; pkexec ufw $rule")
        }
        Repeater {
            model: secPoll.json.firewall.rules || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.fillWidth: true
                    text: "[" + modelData.num + "] " + modelData.to + " " + modelData.action + " " + modelData.from
                    elide: Text.ElideRight
                }
                DeleteButton {
                    onClicked: Quickshell.execDetached(["pkexec", "ufw", "--force", "delete", String(modelData.num)])
                }
            }
        }
    }

    SectionBox {
        title: "Users"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Usuario: ' u; pkexec useradd -m -s /bin/bash \"$u\"")
        }
        Repeater {
            model: secPoll.json.users || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.username + " (" + modelData.uid + ")"
                    elide: Text.ElideRight
                }
                DeleteButton {
                    onClicked: Quickshell.execDetached(["pkexec", "userdel", "-r", modelData.username])
                }
            }
        }
    }
}
