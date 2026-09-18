import QtQuick
import Quickshell.Io

// Equivalente a (defpoll ... :interval "Ns" "cmd") de eww: corre `command`,
// guarda la salida en `text`, y espera `interval` ms desde que termina antes
// de volver a correrlo (evita solapar corridas si un script se cuelga).
// Envuelto en QtObject en vez de heredar de Process porque Process no tiene
// default property para colgarle un Timer directamente.
QtObject {
    id: root
    property var command: []
    // interval <= 0: no se repite solo, corre al arrancar y con refresh().
    property int interval: 3000
    property string text: ""
    // Pausa el polling sin destruir el poller (ej. panel cerrado): la corrida
    // en curso termina, pero no se agenda una nueva hasta volver a true.
    property bool active: true

    // Para scripts que emiten JSON: `json` es `text` ya parseado, o `fallback`
    // si todavia no hubo salida o no es JSON valido.
    property var fallback: null
    readonly property var json: parse(text, fallback)

    function parse(raw, fb) {
        if (!raw || raw.trim().length === 0) return fb
        try { return JSON.parse(raw) } catch (e) { return fb }
    }

    // Re-corre ya (ej. cambio el termino de busqueda) en vez de esperar al
    // proximo tick. Si hay una corrida en curso, encadena otra al terminar
    // para que use el `command` nuevo.
    property bool rerun: false
    function refresh() {
        if (!active) return
        if (proc.running) { rerun = true; return }
        restartTimer.stop()
        proc.running = true
    }

    property Timer restartTimer: Timer {
        interval: root.interval
        onTriggered: if (root.active) root.proc.running = true
    }

    property Process proc: Process {
        command: root.command
        stdout: StdioCollector {
            id: collector
            onStreamFinished: root.text = collector.text.trim()
        }
        onExited: {
            var again = root.rerun
            root.rerun = false
            if (!root.active) return
            if (again) Qt.callLater(() => root.proc.running = true)
            else if (root.interval > 0) root.restartTimer.restart()
        }
        Component.onCompleted: if (root.active) running = true
    }

    onActiveChanged: if (active && !proc.running) proc.running = true
}
