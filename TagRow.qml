import QtQuick
import QtQuick.Layouts

// Fila de opciones tipo "tag": texto plano en mayusculas, separadas por
// barras verticales, verde si esta activa, blanco si no. Usado tanto para
// las pestanas Apps/Code/Cmds del menu como para las opciones del panel de
// sistema (perfiles de energia, wifi, bt, apagado, sub-tabs de Sys).
Item {
    id: root
    property var items: []  // [{ label, active, onClicked }]
    property bool wrap: false  // true: varias filas centradas en vez de una sola
    property int perRow: 4     // items por fila cuando wrap es true
    property bool navigable: true  // false: no participa de la navegacion con flechas (ver Nav)

    Layout.fillWidth: true
    implicitHeight: wrap ? wrapCol.implicitHeight : centeredRow.implicitHeight

    component TagDelegate: RowLayout {
        required property var modelData
        required property int index
        required property bool isLast
        required property bool navigable
        spacing: 12

        ToggleButton {
            navigable: parent.navigable
            text: modelData.label
            active: modelData.active === true
            onClicked: modelData.onClicked()
        }
        Rectangle {
            visible: !isLast
            implicitWidth: 1
            implicitHeight: Theme.sizeTitle
            color: Theme.border
        }
    }

    RowLayout {
        id: centeredRow
        visible: !root.wrap
        anchors.fill: parent
        spacing: 12

        Item { Layout.fillWidth: true }
        Repeater {
            model: root.items
            delegate: TagDelegate { isLast: index === root.items.length - 1; navigable: root.navigable }
        }
        Item { Layout.fillWidth: true }
    }

    function chunk(arr, size) {
        var out = []
        for (var i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size))
        return out
    }

    ColumnLayout {
        id: wrapCol
        visible: root.wrap
        width: parent.width
        spacing: 8

        Repeater {
            model: root.wrap ? root.chunk(root.items, root.perRow) : []
            delegate: RowLayout {
                id: rowDelegate
                required property var modelData
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }
                Repeater {
                    model: rowDelegate.modelData
                    delegate: TagDelegate { isLast: index === rowDelegate.modelData.length - 1; navigable: root.navigable }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
