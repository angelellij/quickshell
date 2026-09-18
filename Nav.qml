pragma Singleton
import QtQuick

// Navegacion con teclado por los "inputs" (botones, links, sliders) de las
// pestanas Sys y AOE2: Arriba/Abajo pasan al siguiente/anterior en orden
// visual, Enter lo activa, Izquierda/Derecha ajustan un slider. Cada
// elemento se registra con un NavTarget; el elegido se marca subrayado.
// Los que estan dentro de un ScrollColumn se scrollean para quedar a la vista.
QtObject {
    readonly property var targets: []
    property var selected: null
    // Posicion (en el orden visual) del elegido: si su elemento se destruye
    // (una lista que se reconstruye al refrescar), se reelige la misma posicion.
    property int lastIndex: -1

    function scrollerOf(item) {
        for (var p = item.parent; p; p = p.parent)
            if (p.isScrollColumn === true) return p
        return null
    }

    // Targets visibles: primero los que estan fuera de un scroll (sub-tabs),
    // despues los del contenido, cada grupo de arriba a abajo y de izq a der.
    function ordered() {
        var list = []
        for (var t of targets) {
            var it = t.item
            if (!t.enabled || !it || !it.visible || it.width <= 0 || it.height <= 0) continue
            var sc = scrollerOf(it)
            var p = it.mapToItem(null, 0, 0)
            list.push({ target: t, group: sc ? 1 : 0, x: p.x, y: p.y + (sc ? sc.contentItem.contentY : 0) })
        }
        list.sort((a, b) => a.group - b.group || (Math.abs(a.y - b.y) > 6 ? a.y - b.y : a.x - b.x))
        return list.map(e => e.target)
    }

    function select(list, index) {
        selected = list[index]
        lastIndex = index
        reveal(selected.item)
    }

    function move(direction) {
        var list = ordered()
        if (list.length === 0) return
        var i = list.indexOf(selected)
        select(list, i < 0 ? (direction > 0 ? 0 : list.length - 1) : (i + direction + list.length) % list.length)
    }

    function activate() {
        if (selected && selected.item && selected.item.visible) selected.activated()
    }

    function adjust(direction) {
        if (selected && selected.adjustable) selected.adjusted(direction)
    }

    function reset() {
        selected = null
        lastIndex = -1
    }

    // Scrollea el ScrollColumn que contiene al item, lo justo para que se vea.
    function reveal(item) {
        var sc = scrollerOf(item)
        if (!sc) return
        var f = sc.contentItem
        // Al subir se deja mas aire arriba para que se vea el titulo de la caja.
        var above = 48
        var below = 24
        var y = item.mapToItem(f.contentItem, 0, 0).y
        if (y - above < f.contentY)
            f.contentY = Math.max(0, y - above)
        else if (y + item.height + below > f.contentY + f.height)
            f.contentY = Math.max(0, Math.min(f.contentHeight - f.height, y + item.height + below - f.height))
    }

    function forget(target) {
        var i = targets.indexOf(target)
        if (i >= 0) targets.splice(i, 1)
        if (selected === target) {
            selected = null
            if (lastIndex >= 0) Qt.callLater(restore)
        }
    }

    function restore() {
        if (selected || lastIndex < 0) return
        var list = ordered()
        if (list.length > 0) selected = list[Math.min(lastIndex, list.length - 1)]
    }

    // Al cambiar de pestana o abrir/cerrar el panel se empieza de cero.
    property Connections bridgeWatch: Connections {
        target: Bridge
        function onActiveTabChanged() { Nav.reset() }
        function onSysTabChanged() { Nav.reset() }
        function onOverviewVisibleChanged() { Nav.reset() }
    }
}
