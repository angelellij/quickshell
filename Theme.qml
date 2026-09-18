pragma Singleton
import QtQuick

QtObject {
    readonly property color bg: "#000000"
    readonly property color bgPanel: "#24252b"
    readonly property color fg: "#cdd6f4"
    readonly property color fgBright: "#ffffff"
    readonly property color accent: "#67bd5a"
    readonly property color accent300: "#5e9356"
    readonly property color border: "#45475a"
    readonly property color danger: "#e06c75"

    // Escala tipografica: solo dos tamanos. Body para listas y texto corrido,
    // title para tags, titulos de seccion, buscador y notificaciones.
    readonly property int sizeBody: 13
    readonly property int sizeTitle: 16

    // Opacidad del texto secundario (etiquetas, hints, items apagados).
    readonly property real dim: 0.6

    readonly property string fontFamily: "JetBrains Mono"
}
