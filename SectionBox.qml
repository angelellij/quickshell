import QtQuick
import QtQuick.Layouts

// Caja con titulo sobre el borde, tipo fieldset. Sirve para las dos cosas:
//  - `rows: [{label, value}]` para una lista fija de datos (System Info), y/o
//  - contenido libre como hijos, para listas clickeables (repos, startup, etc).
Item {
    id: root
    default property alias content: inner.data
    property string title: ""
    property var rows: []  // [{label, value}]

    Layout.fillWidth: true
    implicitHeight: border.height + 12

    Rectangle {
        id: border
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: inner.implicitHeight + 32
        height: implicitHeight
        radius: 4
        color: "transparent"
        border.color: Theme.border
        border.width: 1

        Rectangle {
            x: 12
            y: -titleText.implicitHeight / 2
            width: titleText.implicitWidth + 12
            height: titleText.implicitHeight
            color: Theme.bgPanel

            ThemedText {
                id: titleText
                anchors.centerIn: parent
                text: root.title
                color: Theme.accent
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.pixelSize: Theme.sizeTitle
            }
        }

        ColumnLayout {
            id: inner
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            anchors.topMargin: 20
            spacing: 4

            Repeater {
                model: root.rows
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ThemedText {
                        text: modelData.label
                        Layout.preferredWidth: 90
                        opacity: Theme.dim
                    }
                    ThemedText {
                        text: modelData.value
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
