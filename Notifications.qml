import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Reemplaza a dunst: una linea centrada arriba de la pantalla, "APP - mensaje".
// Solo una notificacion visible a la vez, en cola.
// Ancho completo (para centrar el contenido) pero SOLO mapeada mientras hay
// una notificacion: si quedara siempre mapeada, al ser overlay de ancho
// completo tapa los clicks de todo lo que esta debajo aunque no se vea nada.
// El alto es fijo (no depende del contenido) para que renderice bien desde
// el primer frame en vez de arrancar en 0px.
// Aunque la ventana es una franja ancha, `mask` deja que SOLO el recuadro
// reciba clics: el resto de la franja (transparente) deja pasar los clics a
// lo que este debajo. Clic en el recuadro = descartar la notificacion.
PanelWindow {
    id: root
    screen: Quickshell.screens[0]
    anchors { top: true; left: true; right: true }
    visible: queue.length > 0
    implicitHeight: 90
    color: "transparent"
    exclusiveZone: 0
    mask: Region { item: box }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"

    property var queue: []
    readonly property int defaultTimeout: 4000

    function escapeHtml(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    function truncate(s, max) {
        s = String(s)
        return s.length > max ? s.substring(0, max) + "…" : s
    }

    NotificationServer {
        id: server
        // Ninguno de estos lo implementamos (sin botones, sin imagenes, sin
        // markup propio - el body/summary se muestra como texto plano) asi
        // que se declaran en false: si no, una app puede asumir que estas
        // cosas van a andar y quedarse esperando en silencio.
        actionsSupported: false
        actionIconsSupported: false
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: false
        inlineReplySupported: false
        persistenceSupported: false

        onNotification: (notification) => {
            Quickshell.execDetached(["pw-play", "--volume", "0.2", Sh.assets + "/notification.mp3"])
            notification.tracked = true
            // Si la app la cierra antes de que venza, hay que sacarla de la
            // cola: llamar expire() sobre una notificacion destruida da error.
            notification.closed.connect(() => root.remove(notification))
            root.queue = root.queue.concat([notification])
        }
    }

    // Cierra la notificacion visible (la primera de la cola): por vencimiento
    // (expire) o porque el usuario hizo clic (dismiss). Cualquiera de las dos
    // ya la libera; destrackearla despues daba "Cannot close destroyed
    // notification". La siguiente arranca su timer desde onQueueChanged.
    function closeCurrent(byUser) {
        if (root.queue.length === 0) return
        var n = root.queue[0]
        hideTimer.stop()
        root.queue = root.queue.slice(1)
        if (byUser) n.dismiss()
        else n.expire()
    }

    Timer {
        id: hideTimer
        onTriggered: root.closeCurrent(false)
    }

    function remove(n) {
        var i = root.queue.indexOf(n)
        if (i < 0) return
        if (i === 0) hideTimer.stop()
        root.queue = root.queue.filter(x => x !== n)
    }

    function startHideTimer() {
        var n = root.queue[0]
        var t = (n.expireTimeout && n.expireTimeout > 0) ? n.expireTimeout : root.defaultTimeout
        hideTimer.interval = t
        hideTimer.restart()
    }

    onQueueChanged: if (queue.length > 0 && !hideTimer.running) root.startHideTimer()

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 48
        width: label.implicitWidth + 32
        height: label.implicitHeight + 16
        radius: 6
        color: Theme.bgPanel
        border.color: Theme.accent
        border.width: 1
        opacity: root.queue.length > 0 ? 1 : 0
        visible: opacity > 0

        ThemedText {
            id: label
            anchors.centerIn: parent
            text: root.queue.length > 0
                ? ("<b>" + root.escapeHtml(root.queue[0].appName) + "</b> - " + root.escapeHtml(root.truncate(root.queue[0].summary, 200)))
                : ""
            textFormat: Text.RichText
            font.pixelSize: Theme.sizeTitle
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeCurrent(true)
        }
    }
}
