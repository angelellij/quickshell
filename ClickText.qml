import QtQuick

// Texto clickeable: cursor de mano y navegable con las flechas (ver Nav).
// Elegido con el teclado = subrayado. `hovered` y `selected` quedan
// expuestos para que cada uso decida su color; por defecto pasa a verde.
ThemedText {
    id: root
    property bool navigable: true
    property color baseColor: Theme.fg
    readonly property bool hovered: mouse.containsMouse
    readonly property bool selected: nav.selected
    signal clicked()

    color: hovered || selected ? Theme.accent : baseColor
    font.underline: selected

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    NavTarget {
        id: nav
        item: root
        enabled: root.navigable
        onActivated: root.clicked()
    }
}
