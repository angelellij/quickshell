import QtQuick
import QtQuick.Layouts
import Quickshell

// Info: hardware, uso de CPU/RAM/red y updates pendientes.
SysTab {
    id: root
    tabId: "sysinfo"

    PollingProcess { id: livePoll; active: root.polling; interval: 3000; fallback: ({})
        command: Sh.cmd("sysinfo.py") }
    PollingProcess { id: staticPoll; active: root.polling; interval: 30000; fallback: ({system: {}, hardware: {}})
        command: Sh.cmd("sysinfo-static.py") }
    PollingProcess { id: updatesPoll; active: root.polling; interval: 30000; fallback: []
        command: Sh.cmd("sysinfo-updates.py") }

    SectionBox {
        title: "System"
        rows: [
            { label: "Hostname", value: staticPoll.json.system.hostname || "" },
            { label: "OS",       value: staticPoll.json.system.os || "" },
            { label: "Kernel",   value: staticPoll.json.system.kernel || "" },
            { label: "Arch",     value: staticPoll.json.system.arch || "" },
            { label: "Desktop",  value: staticPoll.json.system.desktop || "" },
            { label: "Uptime",   value: staticPoll.json.system.uptime || "" }
        ]
    }

    SectionBox {
        title: "Hardware"
        rows: [
            { label: "CPU",   value: staticPoll.json.hardware.cpu || "" },
            { label: "Cores", value: staticPoll.json.hardware.cores || "" },
            { label: "GPU",   value: staticPoll.json.hardware.gpu || "" },
            { label: "RAM",   value: staticPoll.json.hardware.ram || "" }
        ].concat((staticPoll.json.hardware.disks || []).map((d, i) => ({ label: "Disk " + i, value: d })))
    }

    SectionBox {
        title: "Usage"
        rows: [
            { label: "CPU",      value: livePoll.json.cpu_pct || "" },
            { label: "CPU Temp", value: livePoll.json.cpu_temp || "" },
            { label: "Load avg", value: livePoll.json.load_avg || "" },
            { label: "Processes",value: String(livePoll.json.processes || "") },
            { label: "RAM",       value: livePoll.json.ram || "" },
            { label: "Swap",      value: livePoll.json.swap || "" },
            { label: "Disk",      value: livePoll.json.disk || "" },
            { label: "Network",   value: livePoll.json.network || "" },
            { label: "↓ RX",  value: livePoll.json.rx || "" },
            { label: "↑ TX",  value: livePoll.json.tx || "" }
        ]
    }

    SectionBox {
        id: updatesBox
        title: "Updates"
        rows: {
            var list = updatesPoll.json || []
            var shown = list.slice(0, 8).map((p) => ({ label: "", value: p }))
            var head = [{ label: "Status", value: list.length + " available" }]
            var tail = list.length > 8 ? [{ label: "", value: "+ " + (list.length - 8) + " more" }] : []
            return head.concat(shown).concat(tail)
        }
    }

    ClickText {
        text: "> Update System"
        baseColor: Theme.accent
        font.pixelSize: Theme.sizeTitle
        font.bold: true
        onClicked: Sh.terminal("sudo apt update && sudo apt upgrade")
    }
}
