pragma Singleton
import QtQuick
import Quickshell

// Unico lugar donde se sabe donde estan los scripts y que terminal/editor se
// usan. Los scripts se ejecutan directo (tienen shebang), sin pasar por
// `bash -c`, asi que las rutas son absolutas y los argumentos van como argv
// (nunca se interpolan en un string de shell).
QtObject {
    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/scripts"
    readonly property string assets: Quickshell.env("HOME") + "/.config/quickshell/assets"
    readonly property string terminalApp: "alacritty"
    readonly property string editorApp: "nvim"

    // argv de un script, para PollingProcess.command o Process.command.
    function cmd(name, args) {
        return [dir + "/" + name].concat(args || [])
    }

    // Corre un script sin terminal y sin esperar.
    function run(name, args) {
        Quickshell.execDetached(cmd(name, args))
    }

    // Corre un snippet de bash en una terminal (para scripts interactivos:
    // prompts con `read`, sudo, etc). Dentro del snippet, $S es la carpeta de
    // scripts y los `args` llegan como $1, $2... Al final espera un Enter
    // para que se alcance a leer la salida.
    function terminal(snippet, args) {
        Quickshell.execDetached([terminalApp, "-e", "bash", "-c",
            "S=\"" + dir + "\"; " + snippet + "; read -p 'Enter para cerrar...'", "_"].concat(args || []))
    }

    // Abre un archivo en el editor, dentro de la terminal.
    function editCmd(path) {
        return [terminalApp, "-e", editorApp, path]
    }
    function edit(path) {
        Quickshell.execDetached(editCmd(path))
    }
}
