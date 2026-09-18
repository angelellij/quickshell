import QtQuick
import QtQuick.Layouts
import Quickshell

// Fila de un jugador en la pestana AOE2: nombre, elo actual (blanco) y
// maximo historico (verde). `elo` y `peak` son null si no hay dato. Click en
// el nombre abre su perfil en aoe2insights.
RowLayout {
    property int playerId: 0
    property string name: ""
    property var elo: null
    property var peak: null

    Layout.fillWidth: true
    spacing: 8

    ClickText {
        Layout.fillWidth: true
        text: parent.name
        elide: Text.ElideRight
        onClicked: {
            Quickshell.execDetached(["xdg-open", "https://www.aoe2insights.com/user/" + parent.playerId + "/"])
            Bridge.overviewVisible = false
        }
    }
    ThemedText {
        Layout.preferredWidth: 50
        horizontalAlignment: Text.AlignRight
        text: parent.elo === null ? "-" : parent.elo
        color: Theme.fgBright
    }
    ThemedText {
        Layout.preferredWidth: 50
        horizontalAlignment: Text.AlignRight
        text: parent.peak === null ? "-" : parent.peak
        color: Theme.accent
    }
}
