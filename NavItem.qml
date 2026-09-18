import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + 20
    radius: 6
    color: mouseArea.containsMouse ? Theme.accent300 : "transparent"

    ThemedText {
        id: label
        anchors.centerIn: parent
        width: parent.width
        text: root.text
        font.pixelSize: Theme.sizeTitle
        font.bold: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
