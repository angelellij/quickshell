import QtQuick
import QtQuick.Layouts

// Base de cada sub-pestana de Sys (SysHome, SysInfo, ...): se muestra solo
// cuando Bridge.sysTab coincide con su tabId, y expone `polling` para que
// sus PollingProcess corran unicamente mientras esa sub-pestana se ve (con
// el panel cerrado, o en otra pestana, no corre ningun script; el ultimo
// resultado queda en cache, asi que al volver se ve al toque y se refresca).
ColumnLayout {
    property string tabId: ""
    readonly property bool polling: Bridge.overviewVisible && Bridge.activeTab === "sys" && Bridge.sysTab === tabId

    visible: Bridge.sysTab === tabId
    Layout.fillWidth: true
    spacing: 16
}
