import QtQuick

// Registra un item como "input" navegable con las flechas (ver Nav.qml).
// Se declara adentro del item: NavTarget { item: root; onActivated: ... }.
QtObject {
    id: root
    property Item item: null
    property bool enabled: true
    // true para sliders: Izquierda/Derecha emiten `adjusted(direccion)`.
    property bool adjustable: false
    readonly property bool selected: Nav.selected === root
    signal activated()
    signal adjusted(int direction)

    Component.onCompleted: Nav.targets.push(root)
    Component.onDestruction: Nav.forget(root)
}
