import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true }
    implicitWidth: 55
    exclusiveZone: 55
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-toolbar"

    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function toggleSystem() {
        if (Bridge.overviewVisible && Bridge.activeTab === "sys") {
            Bridge.overviewVisible = false
        } else {
            Bridge.activeTab = "sys"
            Bridge.overviewVisible = true
        }
    }

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
        anchors.margins: 4
        spacing: 0

        NavItem { text: ">"; onClicked: Bridge.toggleOverview() }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            NavItem { text: "[#]"; onClicked: Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]) }
            // Kb, F11 (fullscreen) y Prt no se usan en este sistema: hay
            // teclado fisico con esas teclas reales. Se dejan comentados
            // para reactivarlos facil en un dispositivo tactil.
            // NavItem { text: "Kb";  onClicked: Quickshell.execDetached(["pkill", "-SIGRTMIN", "-f", "wvkbd-mobintl-custom"]) }
            // NavItem { text: "F11"; onClicked: Sh.run("toggle-fullscreen-50.sh") }
            // NavItem { text: "Prt"; onClicked: Quickshell.execDetached(["niri", "msg", "action", "screenshot"]) }
        }

        Separator {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            NavItem { text: "Ch"; onClicked: Quickshell.execDetached(["google-chrome-stable"]) }
            NavItem { text: "Fi"; onClicked: Quickshell.execDetached(["nautilus"]) }
            NavItem { text: "Di"; onClicked: Quickshell.execDetached(["discord"]) }
            NavItem { text: "Te"; onClicked: Quickshell.execDetached([Sh.terminalApp]) }
            NavItem { text: "AOE"; onClicked: Quickshell.execDetached(["steam", "steam://rungameid/813780"]) }
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Separator {}
            StatItem { etiqueta: "HOR"; valor: Qt.formatDateTime(root.now, "hh"); onClicked: root.toggleSystem() }
            StatItem { etiqueta: "MIN"; valor: Qt.formatDateTime(root.now, "mm"); onClicked: root.toggleSystem() }
            StatItem { etiqueta: "DIA"; valor: Qt.formatDateTime(root.now, "dd"); onClicked: root.toggleSystem() }
            StatItem { etiqueta: "MES"; valor: Qt.formatDateTime(root.now, "MM"); onClicked: root.toggleSystem() }
            Separator {}
            StatItem { etiqueta: "CPU"; valor: Stats.cpu; onClicked: root.toggleSystem() }
            StatItem { etiqueta: "GPU"; valor: Stats.gpu; onClicked: root.toggleSystem() }
            StatItem { etiqueta: "RAM"; valor: Stats.ram; onClicked: root.toggleSystem() }
            Separator {}
            StatItem { etiqueta: "VOL"; valor: Stats.volumen; onClicked: root.toggleSystem() }
            StatItem { etiqueta: "MIC"; valor: Stats.micVol; onClicked: root.toggleSystem() }
            // Sin bateria en este sistema (es un desktop).
            // StatItem { etiqueta: "BAT"; valor: Stats.bateria }
        }
    }
}
