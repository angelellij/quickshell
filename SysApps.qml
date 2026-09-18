import QtQuick
import QtQuick.Layouts
import Quickshell

// Apps: comandos, repos, startup, default apps y launchers.
SysTab {
    id: root
    tabId: "apps"


    // Lista completa de launchers instalados, sin filtro de busqueda.
    PollingProcess { id: launchersPoll; active: root.polling; interval: 5000; fallback: []
        command: Sh.cmd("list-apps.sh") }
    PollingProcess { id: appsInfoPoll; active: root.polling; interval: 3000; fallback: ({repos: [], startup: [], default_apps: [], commands: []})
        command: Sh.cmd("sys-apps-info.py") }

    SectionBox {
        title: "Commands"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Nombre: ' name; path=$(\"$S/sys-create-command.py\" \"$name\") && nvim \"$path\"")
        }
        Repeater {
            model: appsInfoPoll.json.commands || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ClickText {
                    Layout.fillWidth: true
                    text: modelData.name
                    elide: Text.ElideRight
                    onClicked: Sh.edit(modelData.path)
                }
                DeleteButton {
                    onClicked: Sh.run("sys-delete-file.py", [modelData.path])
                }
            }
        }
    }

    SectionBox {
        title: "Repos"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Nombre (archivo .list): ' name; read -p 'Linea deb: ' deb; \"$S/sys-create-repo.py\" \"$name\" \"$deb\"")
        }
        Repeater {
            model: appsInfoPoll.json.repos || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleButton {
                    Layout.fillWidth: true
                    text: modelData.suite + " (" + modelData.url.replace(/^https?:\/\//, "") + ")"
                    active: modelData.enabled
                    strikeInactive: true
                    plain: true
                    onClicked: Sh.terminal("\"$S/sys-toggle-repo.py\" \"$1\" \"$2\" \"$3\" \"$4\"", [modelData.file, String(modelData.line_num), modelData.format, String(modelData.enabled)])
                }
                DeleteButton {
                    visible: modelData.file !== "/etc/apt/sources.list"
                    onClicked: Sh.terminal("\"$S/sys-delete-repo.py\" \"$1\"", [modelData.file])
                }
            }
        }
    }

    SectionBox {
        title: "Startup"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Nombre: ' name; path=$(\"$S/sys-create-startup.py\" \"$name\") && nvim \"$path\"")
        }
        Repeater {
            model: appsInfoPoll.json.startup || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleButton {
                    Layout.fillWidth: true
                    text: modelData.name
                    active: modelData.enabled
                    strikeInactive: true
                    plain: true
                    onClicked: Sh.run("sys-toggle-startup.py", [modelData.path, String(modelData.enabled)])
                }
                DeleteButton {
                    onClicked: Sh.run("sys-delete-file.py", [modelData.path])
                }
            }
        }
    }

    SectionBox {
        title: "Default Apps"
        Repeater {
            model: appsInfoPoll.json.default_apps || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    text: modelData.label
                    Layout.preferredWidth: 100
                    opacity: Theme.dim
                }
                ClickText {
                    text: modelData.app || "(ninguno)"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    baseColor: Theme.accent
                    onClicked: Sh.terminal("read -e -p \"App .desktop para $2 ($1): \" -i \"$3\" app; xdg-mime default \"$app\" \"$2\"", [modelData.label, modelData.mime, modelData.app])
                }
            }
        }
    }

    SectionBox {
        title: "App Launchers"
        ActionButton {
            label: "Create"
            onClicked: Sh.terminal("read -p 'Nombre: ' name; path=$(\"$S/sys-create-app.py\" \"$name\") && nvim \"$path\"")
        }
        Repeater {
            model: launchersPoll.json
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ClickText {
                    Layout.fillWidth: true
                    text: modelData.name
                    elide: Text.ElideRight
                    onClicked: Sh.edit(modelData.path)
                }
                DeleteButton {
                    onClicked: Sh.run("sys-delete-app.py", [modelData.path])
                }
            }
        }
    }
}
