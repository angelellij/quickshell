import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Columna scrolleable con barra fina (4px) que ocupa todo el alto disponible.
// Los hijos se apilan adentro con 16px de separacion; se deja lugar a la
// derecha para que la barra no pise los bordes de las cajas.
ScrollView {
    id: root
    default property alias content: column.data
    readonly property bool isScrollColumn: true  // Nav.reveal() la busca por esto

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        width: 4
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.border
        }
        background: null
    }

    ColumnLayout {
        id: column
        width: root.availableWidth - 14
        spacing: 16
    }
}
