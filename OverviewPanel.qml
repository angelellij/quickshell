import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

// Panel ancho que se abre al tocar ">" (o Mod+Space): pestanas Apps/Code/Cmds
// con buscador compartido, mas las pestanas Sys (ver SysPanel.qml) y AOE2 (Aoe2Panel.qml). El
// filtrado lo hacen los scripts (list-apps.sh etc), no aca: se les pasa el
// texto tipeado como argumento y se re-corren cuando cambia.
PanelWindow {
    id: root
    screen: Quickshell.screens[0]
    visible: Bridge.overviewVisible
    anchors { top: true; bottom: true; left: true }
    implicitWidth: screen ? screen.width : 1536
    exclusiveZone: 0
    color: "transparent"

    // A diferencia de eww, aca se puede pedir foco de teclado on-demand:
    // arregla el bug de que el buscador no tomaba las teclas.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-overview"

    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0
            searchField.forceActiveFocus()
        }
    }

    // Cada lista solo se pollea mientras su pestana se ve. El texto del
    // buscador va como argumento ($1) y al tipear se re-corre al instante
    // (refresh); el intervalo largo es solo para enterarse de cambios de
    // afuera (una app nueva instalada, etc).
    PollingProcess {
        id: appsPoll
        active: root.visible && Bridge.activeTab === "apps"
        interval: 3000
        fallback: []
        command: Sh.cmd("list-apps.sh", [Bridge.searchText])
    }
    PollingProcess {
        id: codePoll
        active: root.visible && Bridge.activeTab === "code"
        interval: 3000
        fallback: []
        command: Sh.cmd("list-code.sh", [Bridge.searchText])
    }
    PollingProcess {
        id: cmdsPoll
        active: root.visible && Bridge.activeTab === "cmds"
        interval: 3000
        fallback: []
        command: Sh.cmd("list-commands.sh", [Bridge.searchText])
    }

    property var listModel: []
    property int selectedIndex: 0

    readonly property var tabOrder: ["apps", "code", "cmds", "sys", "aoe2"]
    // Sys y AOE2 tienen su propio contenido: sin buscador ni lista de lanzadores.
    readonly property bool listTab: Bridge.activeTab !== "sys" && Bridge.activeTab !== "aoe2"

    function refreshList() {
        if (!listTab) {
            listModel = []
            selectedIndex = 0
            return
        }
        var poll = Bridge.activeTab === "apps" ? appsPoll
                 : (Bridge.activeTab === "code" ? codePoll : cmdsPoll)
        // parse() directo sobre .text (no poll.json): este handler corre en
        // el mismo signal que actualiza json, y el orden no esta garantizado.
        listModel = poll.parse(poll.text, [])
        selectedIndex = 0
    }

    function runSelected() {
        if (selectedIndex < 0 || selectedIndex >= listModel.length) return
        Quickshell.execDetached(["bash", "-c", listModel[selectedIndex].exec])
        Bridge.overviewVisible = false
    }

    Connections { target: appsPoll; function onTextChanged() { if (Bridge.activeTab === "apps") root.refreshList() } }
    Connections { target: codePoll; function onTextChanged() { if (Bridge.activeTab === "code") root.refreshList() } }
    Connections { target: cmdsPoll; function onTextChanged() { if (Bridge.activeTab === "cmds") root.refreshList() } }
    Connections { target: Bridge; function onActiveTabChanged() { root.refreshList() } }
    Connections {
        target: Bridge
        function onSearchTextChanged() {
            if (searchField.text !== Bridge.searchText) searchField.text = Bridge.searchText
            appsPoll.refresh()
            codePoll.refresh()
            cmdsPoll.refresh()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.preferredWidth: 460
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.bgPanel
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: Theme.accent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                TagRow {
                    Layout.fillWidth: true
                    navigable: false  // estas pestanas se cambian con Tab
                    items: [
                        { label: "Apps", active: Bridge.activeTab === "apps", onClicked: () => Bridge.activeTab = "apps" },
                        { label: "Code", active: Bridge.activeTab === "code", onClicked: () => Bridge.activeTab = "code" },
                        { label: "Cmds", active: Bridge.activeTab === "cmds", onClicked: () => Bridge.activeTab = "cmds" },
                        { label: "Sys",  active: Bridge.activeTab === "sys",  onClicked: () => Bridge.activeTab = "sys" },
                        { label: "Aoe2", active: Bridge.activeTab === "aoe2", onClicked: () => Bridge.activeTab = "aoe2" }
                    ]
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    // No se oculta con visible:false porque perderia el foco
                    // de teclado (Tab/flechas/Esc/Enter siguen andando en Sys).
                    Layout.preferredHeight: root.listTab ? -1 : 0
                    opacity: root.listTab ? 1 : 0
                    clip: true
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeTitle
                    color: Theme.fg
                    padding: 8
                    leftPadding: 20

                    background: Rectangle {
                        color: "transparent"

                        ThemedText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: ">"
                            color: Theme.accent
                            font.pixelSize: Theme.sizeTitle
                            font.bold: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.accent
                        }
                    }

                    onTextChanged: Bridge.searchText = text

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) {
                            var idx = root.tabOrder.indexOf(Bridge.activeTab)
                            Bridge.activeTab = root.tabOrder[(idx + 1) % root.tabOrder.length]
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                            var idxBack = root.tabOrder.indexOf(Bridge.activeTab)
                            Bridge.activeTab = root.tabOrder[(idxBack - 1 + root.tabOrder.length) % root.tabOrder.length]
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                            var step = event.key === Qt.Key_Down ? 1 : -1
                            if (!root.listTab)
                                Nav.move(step)   // Sys / AOE2: siguiente input
                            else if (root.listModel.length > 0)
                                root.selectedIndex = (root.selectedIndex + step + root.listModel.length) % root.listModel.length
                            event.accepted = true
                        } else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && !root.listTab && Nav.selected && Nav.selected.adjustable) {
                            Nav.adjust(event.key === Qt.Key_Right ? 1 : -1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            Bridge.overviewVisible = false
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.listTab) root.runSelected()
                            else Nav.activate()
                            event.accepted = true
                        }
                    }
                }

                ListView {
                    id: listView
                    visible: root.listTab
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.listModel
                    currentIndex: root.selectedIndex
                    highlightFollowsCurrentItem: true

                    delegate: Rectangle {
                        width: listView.width
                        implicitHeight: itemLabel.implicitHeight + 24
                        radius: 6
                        color: "transparent"

                        readonly property bool active: index === root.selectedIndex || itemMouse.containsMouse

                        ThemedText {
                            id: itemLabel
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14
                            text: active ? ("> " + modelData.name) : modelData.name
                            color: active ? Theme.accent : Theme.fg
                            font.pixelSize: Theme.sizeTitle
                            font.capitalization: active ? Font.AllUppercase : Font.MixedCase
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: {
                                root.selectedIndex = index
                                root.runSelected()
                            }
                        }
                    }
                }

                SysPanel {}
                Aoe2Panel {}
            }
        }

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            onClicked: Bridge.overviewVisible = false
        }
    }
}
