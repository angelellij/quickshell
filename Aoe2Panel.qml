import QtQuick
import QtQuick.Layouts
import Quickshell

// Contenido de la pestana AOE2 de OverviewPanel: acciones y ranking 1v1 de
// los jugadores seguidos, agrupados por grupo (ver Aoe2.qml y scripts/aoe2.py).
ScrollColumn {
    visible: Bridge.activeTab === "aoe2"

    SectionBox {
        title: "AOE2"
        ActionButton {
            label: "Abrir AOE2 DE"
            onClicked: {
                Quickshell.execDetached(["steam", "steam://rungameid/813780"])
                Bridge.overviewVisible = false
            }
        }
        ActionButton {
            label: "Editar jugadores seguidos"
            onClicked: {
                Aoe2.editor.running = true
                Bridge.overviewVisible = false
            }
        }
        ActionButton {
            label: Aoe2.refreshing ? "Actualizando..." : "Actualizar datos"
            onClicked: Aoe2.refresh()
        }
    }

    Repeater {
        model: Aoe2.groups
        delegate: SectionBox {
            title: modelData.name
            Repeater {
                model: modelData.players
                delegate: Aoe2Row {
                    playerId: modelData.id
                    name: modelData.name
                    elo: modelData.elo
                    peak: modelData.max
                }
            }
        }
    }

    SectionBox {
        visible: Aoe2.matches.length === 0
        title: "Partidas"
        ThemedText {
            text: Aoe2.liveFailed ? "Sin conexion" : "Ninguna en curso"
            opacity: Theme.dim
        }
    }

    // Un recuadro por partida en curso: tipo de partida como titulo y los
    // jugadores de cada equipo, con una linea entre equipos.
    Repeater {
        model: Aoe2.matches
        delegate: SectionBox {
            title: modelData.type
            Repeater {
                model: modelData.teams
                delegate: ColumnLayout {
                    id: team
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        visible: team.index > 0
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        implicitHeight: 1
                        color: Theme.border
                    }
                    Repeater {
                        model: team.modelData
                        delegate: Aoe2Row {
                            playerId: modelData.id
                            name: modelData.name
                            elo: modelData.elo
                            peak: modelData.max
                        }
                    }
                }
            }
        }
    }

    ThemedText {
        Layout.fillWidth: true
        text: (Aoe2.updated > 0 ? "Actualizado " + Qt.formatDateTime(new Date(Aoe2.updated * 1000), "dd/MM hh:mm") : "Sin datos")
            + (Aoe2.stale ? " (sin conexion)" : "")
        horizontalAlignment: Text.AlignRight
        opacity: Theme.dim

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Aoe2.refresh()
        }
    }
}
