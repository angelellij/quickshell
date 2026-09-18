import QtQuick
import QtQuick.Layouts
import Quickshell

// Other: settings, locale y fuentes.
SysTab {
    id: root
    tabId: "other"

    PollingProcess { id: otherPoll; active: root.polling; interval: 5000; fallback: ({settings: {}, locale: {}, fonts: []})
        command: Sh.cmd("sys-other-info.py") }

    SectionBox {
        title: "Settings"

        ToggleButton {
            Layout.fillWidth: true
            text: "Editor: " + (otherPoll.json.settings.editor || "")
            active: false
            plain: true
            onClicked: Sh.terminal("echo 'Disponibles: $1'; read -e -p 'Editor: ' -i \"$2\" v; \"$S/sys-set-setting.py\" editor \"$v\"", [(otherPoll.json.settings.available_editors || []).join(", "), otherPoll.json.settings.editor || ""])
        }
        ToggleButton {
            Layout.fillWidth: true
            text: "Theme: " + (otherPoll.json.settings.theme || "")
            active: false
            plain: true
            onClicked: Sh.terminal("read -e -p 'Theme: ' -i \"$1\" v; \"$S/sys-set-setting.py\" theme \"$v\"", [otherPoll.json.settings.theme || ""])
        }
    }

    SectionBox {
        title: "Locale"

        ToggleButton {
            Layout.fillWidth: true
            text: "Locale: " + (otherPoll.json.locale.locale || "")
            active: false
            plain: true
            onClicked: Sh.terminal("read -e -p 'Locale (ej. en_US.UTF-8): ' -i \"$1\" v; localectl set-locale \"LANG=$v\"", [otherPoll.json.locale.locale || ""])
        }
        ToggleButton {
            Layout.fillWidth: true
            text: "Timezone: " + (otherPoll.json.locale.timezone || "")
            active: false
            plain: true
            onClicked: Sh.terminal("read -e -p 'Timezone (ej. America/Buenos_Aires): ' -i \"$1\" v; timedatectl set-timezone \"$v\"", [otherPoll.json.locale.timezone || ""])
        }
        ToggleButton {
            Layout.fillWidth: true
            text: "Keyboard: " + (otherPoll.json.locale.keyboard || "")
            active: false
            plain: true
            onClicked: Sh.terminal("read -e -p 'Keyboard layout (ej. es, us): ' -i \"$1\" v; localectl set-x11-keymap \"$v\"", [otherPoll.json.locale.keyboard || ""])
        }
    }

    SectionBox {
        title: "Fonts"
        ActionButton {
            label: "Install font"
            onClicked: Sh.terminal("read -e -p 'Ruta al archivo (.ttf/.otf/.woff/.woff2): ' path; \"$S/sys-install-font.py\" \"$path\"")
        }
        Repeater {
            model: otherPoll.json.fonts || []
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.name + " (" + modelData.format + ")"
                    elide: Text.ElideRight
                }
                DeleteButton {
                    onClicked: Sh.run("sys-delete-font.py", [modelData.path])
                }
            }
        }
    }
}
