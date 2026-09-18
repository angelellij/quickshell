import QtQuick
import QtQuick.Layouts

// Barra estilo terminal (bloques Unicode) en vez del slider redondeado de
// QtQuick.Controls, para que combine con el resto de la UI (mono, sin
// bordes redondeados, verde/blanco).
RowLayout {
    id: root
    property string label: ""
    property real min: 0
    property real max: 100
    property real valueNum: 0
    signal changed(real value)

    // Izquierda/Derecha con el slider elegido (ver Nav): pasos del 5% del rango.
    // `lastSent` evita partir de un valor viejo si se aprieta varias veces
    // antes de que el valor real se actualice.
    property real lastSent: NaN
    onValueNumChanged: lastSent = NaN
    function step(direction) {
        var base = isNaN(lastSent) ? valueNum : lastSent
        lastSent = Math.max(min, Math.min(max, base + direction * (max - min) / 20))
        changed(lastSent)
    }

    readonly property real fraction: Math.max(0, Math.min(1, (valueNum - min) / (max - min)))
    readonly property int barChars: Math.max(4, Math.floor(barContainer.width / Math.max(1, fm.advanceWidth("█"))))
    readonly property int filledChars: Math.round(fraction * barChars)

    Layout.fillWidth: true
    spacing: 12

    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeTitle
    }

    function setFromX(x) {
        var frac = Math.max(0, Math.min(1, x / barContainer.width))
        root.changed(root.min + frac * (root.max - root.min))
    }

    ThemedText {
        text: root.label
        Layout.preferredWidth: 190
        elide: Text.ElideRight
        font.pixelSize: Theme.sizeTitle
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.underline: nav.selected
        color: nav.selected ? Theme.accent : Theme.fgBright
    }

    NavTarget {
        id: nav
        item: root
        adjustable: true
        onAdjusted: (direction) => root.step(direction)
    }

    Item {
        id: barContainer
        Layout.fillWidth: true
        implicitHeight: barRow.implicitHeight
        clip: true

        Row {
            id: barRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            ThemedText {
                text: "█".repeat(root.filledChars)
                color: Theme.accent
                font.pixelSize: Theme.sizeTitle
            }
            ThemedText {
                text: "░".repeat(root.barChars - root.filledChars)
                color: Theme.border
                font.pixelSize: Theme.sizeTitle
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: (mouse) => root.setFromX(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) root.setFromX(mouse.x) }
        }
    }
}
