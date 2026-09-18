pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

// Variables dinamicas que muestra el toolbar (siempre visibles, por eso no se
// pausan). Ninguna lanza procesos: CPU/RAM/GPU se leen directo de /proc y
// /sys cada 3 s, y el volumen llega por eventos de Pipewire.
// Lo que solo usa una sub-pestana de Sys (wifi, perfil de energia, etc)
// vive en esa sub-pestana y se pollea solo mientras se ve.
// Cada objeto se declara como property explicita porque QtObject (a
// diferencia de Item) no tiene default property para hijos sueltos.
QtObject {
    property FileView statFile: FileView { path: "/proc/stat"; blockLoading: true }
    property FileView memFile: FileView { path: "/proc/meminfo"; blockLoading: true }
    property FileView gpuFile: FileView { path: "/sys/class/drm/card0/device/gpu_busy_percent"; blockLoading: true; printErrors: false }

    property string cpu: "0%"
    property string ram: "0%"
    property string gpu: "0%"

    // Uso de CPU entre dos lecturas (mismas cuentas que tenia cpu.sh, pero sin
    // el sleep 0.5): usuario+sistema sobre usuario+nice+sistema+idle. La
    // primera vez da el promedio desde el arranque.
    property double prevBusy: 0
    property double prevTotal: 0

    function sample() {
        statFile.reload()
        var c = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        var busy = c[0] + c[2]
        var total = c[0] + c[1] + c[2] + c[3]
        var dt = total - prevTotal
        cpu = (dt > 0 ? Math.round((busy - prevBusy) * 100 / dt) : 0) + "%"
        prevBusy = busy
        prevTotal = total

        // Memoria usada como la calculaba el awk de antes: total - libre - buffers - cache.
        memFile.reload()
        var mem = memFile.text()
        var kb = (name) => Number((new RegExp("^" + name + ":\\s+(\\d+)", "m").exec(mem) || [0, 0])[1])
        var t = kb("MemTotal")
        ram = (t > 0 ? Math.round((t - kb("MemFree") - kb("Buffers") - kb("Cached")) / t * 100) : 0) + "%"

        // Sin GPU compatible (o sin permiso), el archivo no existe: queda en 0%.
        if (Features.gpu) {
            try {
                gpuFile.reload()
                gpu = (parseInt(gpuFile.text()) || 0) + "%"
            } catch (e) {
                gpu = "0%"
            }
        }
    }

    property Timer sampler: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: Stats.sample()
    }

    // Volumen y mic por Pipewire, por eventos: no lanza ningun proceso (antes
    // era un bash + wpctl por segundo). El tracker hace falta para que el nodo
    // exponga `audio` (volumen/mute).
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property PwObjectTracker audioTracker: PwObjectTracker { objects: [Stats.sink, Stats.source] }

    property PollingProcess batProc: PollingProcess { active: Features.battery; interval: 30000; command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity | awk '{print $1\"%\"}'"] }
    property PollingProcess brilloProc: PollingProcess { active: Features.brightness; interval: 2000; command: ["bash", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"] }

    // Solo lectura: escribir `audio.volume` desde aca no tiene efecto real en
    // este sistema (sink Bluetooth; el volumen va por la ruta del dispositivo),
    // asi que los sliders de SysHome siguen usando `wpctl set-volume`.
    function percent(node) {
        return node && node.audio ? Math.round(node.audio.volume * 100) : 0
    }

    readonly property int volumenNum: percent(sink)
    readonly property int micVolNum: percent(source)
    readonly property string volumen: volumenNum + "%"
    readonly property string micVol: micVolNum + "%"

    readonly property string bateria: batProc.text
    readonly property int brilloNum: parseInt(brilloProc.text) || 0
    readonly property string brillo: brilloNum + "%"
}
