import Quickshell.Io

// Permite togglear el panel "#" desde afuera del proceso, por ejemplo desde
// un keybind de niri: `quickshell ipc call overview toggle`.
IpcHandler {
    target: "overview"

    function toggle() {
        Bridge.toggleOverview()
    }
}
