import QtQuick

// "x" a la derecha de un item de lista, para borrarlo/matarlo. Pide
// confirmacion: el primer toque (o Enter) la arma (se pone roja unos
// segundos), el segundo confirma. No hace falta un dialogo aparte.
ThemedText {
    id: root
    signal clicked()
    property bool armed: false
    readonly property bool selected: nav.selected

    text: "✕"
    color: armed ? Theme.danger : (selected ? Theme.accent : Theme.fg)
    opacity: armed || selected || mouse.containsMouse ? 1 : Theme.dim
    font.bold: true
    font.underline: selected

    function press() {
        if (armed) {
            armed = false
            resetTimer.stop()
            clicked()
        } else {
            armed = true
            resetTimer.restart()
        }
    }

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: root.armed = false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.press()
    }
    NavTarget {
        id: nav
        item: root
        onActivated: root.press()
    }
}
