pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Que widgets/paneles mostrar en esta maquina. Lee dos JSON de
// ~/.config/quickshell/: features.default.json (todo prendido, versionado
// como base) y features.<hostname>.json (solo las diferencias de esta
// maquina, tambien versionado). Si no hay archivo especifico para el
// hostname actual, se usan los defaults tal cual.
//
// Asi el hardware de cada maquina no se resuelve editando los componentes
// (Toolbar.qml, Stats.qml, etc, quedan iguales en todas), sino con un JSON
// nuevo por hostname: cambiar de PC es agregar/editar ese archivo, no pelear
// con git en el codigo compartido.
QtObject {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell"

    property FileView hostFile: FileView { path: "/etc/hostname"; blockLoading: true; printErrors: false }
    readonly property string hostname: hostFile.text().trim()

    property FileView defaultFile: FileView {
        path: root.configDir + "/features.default.json"
        blockLoading: true
    }
    property FileView overrideFile: FileView {
        path: root.hostname ? (root.configDir + "/features." + root.hostname + ".json") : ""
        blockLoading: true
        printErrors: false
    }

    function parse(fv) {
        try { return JSON.parse(fv.text()) } catch (e) { return {} }
    }

    readonly property var defaults: parse(defaultFile)
    readonly property var overrides: parse(overrideFile)

    function flag(name) {
        if (overrides && name in overrides) return overrides[name]
        if (defaults && name in defaults) return defaults[name]
        return false
    }

    readonly property bool gpu: flag("gpu")
    readonly property bool battery: flag("battery")
    readonly property bool brightness: flag("brightness")
    readonly property bool virtualKeyboard: flag("virtualKeyboard")
    readonly property bool fullscreenToggle: flag("fullscreenToggle")
    readonly property bool screenshot: flag("screenshot")
    readonly property bool aoe2Panel: flag("aoe2Panel")
    readonly property bool aoe2Launcher: flag("aoe2Launcher")
}
