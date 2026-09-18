import QtQuick

// Texto base de la interfaz: fuente, tamano (body) y color del tema. Cada
// uso solo declara lo que cambia (title en vez de body, acento, etc).
Text {
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.sizeBody
}
