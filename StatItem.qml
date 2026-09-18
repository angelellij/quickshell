import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string etiqueta: ""
    property string valor: ""
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 12
    radius: 6
    color: "transparent"

    Column {
        id: col
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        ThemedText {
            width: parent.width
            text: root.etiqueta
            color: Theme.accent
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }
        ThemedText {
            width: parent.width
            text: root.valor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
