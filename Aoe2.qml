pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Estado de la pestana AOE2. Vive como singleton (y no dentro de la pestana)
// porque el poll de ELO tiene que correr cada hora aunque el panel este
// cerrado: cada corrida de aoe2.py anota los ratings en el historial.
//
// Ninguno de los dos polls se repite solo (interval: 0): todo pasa por
// refresh(). Las consultas automaticas (timer horario, abrir la pestana) van
// por refreshIfStale(), que exige minGap desde la ultima consulta; las
// manuales (boton, cerrar el editor de jugadores) llaman a refresh() directo.
QtObject {
    readonly property string playersFile: Quickshell.env("HOME") + "/.config/quickshell/aoe2-players.csv"

    property PollingProcess poll: PollingProcess {
        interval: 0
        fallback: ({ stale: false, updated: 0, groups: [] })
        command: Sh.cmd("aoe2.py")
    }

    // Partidas en curso con jugadores seguidos:
    // [{ id, type, since, teams: [[{ id, name, elo, max }]] }], con todos los
    // jugadores de la partida (rivales incluidos). Si la consulta falla no se
    // conserva la lista anterior (podria mostrar partidas que ya terminaron):
    // queda vacia y liveFailed en true.
    property PollingProcess livePoll: PollingProcess {
        interval: 0
        fallback: ({ matches: null })
        command: Sh.cmd("aoe2.py", ["live"])
    }
    property var matches: []
    property bool liveFailed: false
    property Connections liveUpdates: Connections {
        target: Aoe2.livePoll
        function onTextChanged() {
            var j = Aoe2.livePoll.parse(Aoe2.livePoll.text, null)
            Aoe2.liveFailed = !j || j.matches === null
            Aoe2.matches = (j && j.matches) || []
        }
    }

    // [{ name, players: [{ id, name, elo }] }]: grupos ya ordenados por el script.
    readonly property var groups: poll.json.groups || []
    readonly property bool stale: poll.json.stale === true
    readonly property real updated: poll.json.updated || 0

    // Minimo entre consultas automaticas. Al arrancar quickshell ya corren
    // ambos polls, y eso cuenta como la ultima vez.
    readonly property int minGap: 300000
    property double lastRefresh: Date.now()

    // Re-consulta ya elo y partidas en curso, sin importar cuando fue la
    // ultima vez. `refreshing` es true mientras cualquiera de las dos corre.
    function refresh() {
        lastRefresh = Date.now()
        poll.refresh()
        livePoll.refresh()
    }
    function refreshIfStale() {
        if (Date.now() - lastRefresh > minGap) refresh()
    }
    readonly property bool refreshing: poll.proc.running || livePoll.proc.running

    // Automaticas: cada hora (anota el historial aunque el panel este
    // cerrado) y al abrir la pestana AOE2.
    property Timer hourly: Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: Aoe2.refreshIfStale()
    }
    readonly property bool tabOpen: Bridge.overviewVisible && Bridge.activeTab === "aoe2"
    onTabOpenChanged: if (tabOpen) refreshIfStale()

    // Edita la lista de jugadores (CSV: id y grupo) en nvim y, al cerrar, re-consulta ya
    // (forzado: el CSV cambio) para que se vean los cambios.
    property Process editor: Process {
        command: Sh.editCmd(Aoe2.playersFile)
        onExited: Aoe2.refresh()
    }
}
