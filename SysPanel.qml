import QtQuick
import QtQuick.Layouts

// Contenido de la pestana Sys de OverviewPanel: sub-pestanas fijas arriba
// (no scrollean) y, abajo, el area scrolleable con un componente por
// sub-pestana. Para sumar una nueva: crear SysXxx.qml basado en SysTab,
// instanciarlo abajo y agregarla a `subTabs`.
ColumnLayout {
    id: root
    readonly property var subTabs: [
        { id: "home",    label: "Home" },
        { id: "sysinfo", label: "Info" },
        { id: "apps",    label: "Apps" },
        { id: "audio",   label: "Audio" },
        { id: "srvs",    label: "Srvs" },
        { id: "sec",     label: "Sec" },
        { id: "proc",    label: "Proc" },
        { id: "other",   label: "Other" }
    ]

    visible: Bridge.activeTab === "sys"
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 16

    TagRow {
        Layout.fillWidth: true
        wrap: true
        items: root.subTabs.map((t) => ({
            label: t.label,
            active: Bridge.sysTab === t.id,
            onClicked: () => Bridge.sysTab = t.id
        }))
    }

    ScrollColumn {
        SysHome {}
        SysInfo {}
        SysApps {}
        SysAudio {}
        SysSrvs {}
        SysSec {}
        SysProc {}
        SysOther {}
    }
}
