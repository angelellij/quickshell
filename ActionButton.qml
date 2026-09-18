import QtQuick
import QtQuick.Layouts

// Boton de accion de texto: "<texto>" en blanco, verde al pasar el mouse.
// Lo usan la pestana AOE2 y los Create/Add/Scan de las sub-pestanas de Sys.
ClickText {
    id: root
    property string label: ""

    Layout.alignment: Qt.AlignLeft
    Layout.topMargin: 4
    // Sin esto Qt toma "<texto>" por HTML y lo hace desaparecer.
    textFormat: Text.PlainText
    text: "<" + label + ">"
    baseColor: Theme.fgBright
}
