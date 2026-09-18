pragma Singleton
import QtQuick

// Estado compartido entre Toolbar y OverviewPanel, equivalente a
// los (defvar ...) globales de eww.yuck.
QtObject {
    property bool overviewVisible: false
    property string activeTab: "apps"
    property string searchText: ""

    // Sub-pestana dentro del tab Sys (Home, y a futuro Audio/Power/etc,
    // calcadas de las secciones del repo textual-config).
    property string sysTab: "home"

    // Usado tanto por el "#" del Toolbar como por el IPC handler (Mod+Space
    // en niri) - antes estaba duplicado en los dos lugares.
    function toggleOverview() {
        searchText = ""
        activeTab = "apps"
        overviewVisible = !overviewVisible
    }
}
