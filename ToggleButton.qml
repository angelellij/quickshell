import QtQuick

// Mismo formato que los tags del menu "#": sin caja, verde si esta activo,
// blanco si no, en mayusculas. Elegido con el teclado = subrayado.
ClickText {
    id: root
    property bool active: false
    property bool strikeInactive: false
    // Para listas de items (Repos/Startup/etc): texto normal sin mayusculas.
    property bool plain: false
    // En modo plain, si ademas queres que el elegido/activo se vea en verde
    // (ej. Audio/WiFi/BT). Repos y Startup lo dejan en false a proposito.
    property bool accentActive: false

    readonly property bool showAccent: active && (!plain || accentActive)

    font.pixelSize: plain ? Theme.sizeBody : Theme.sizeTitle
    font.bold: !plain
    font.capitalization: plain ? Font.MixedCase : Font.AllUppercase
    font.strikeout: strikeInactive && !active
    color: showAccent ? Theme.accent : (plain ? Theme.fg : Theme.fgBright)
    elide: Text.ElideRight
}
