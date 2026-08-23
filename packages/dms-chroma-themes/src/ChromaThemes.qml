import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string trigger: "#theme"

    signal itemsChanged

    // Filled in from chroma-theme-list; getItems has to answer synchronously,
    // so it serves this cache and refreshes behind the user's back.
    // Kept in sync with the daemon surface, which writes the pins.
    readonly property string stateId: "chromaThemes"

    property var themes: []
    property string activeTheme: ""
    property double lastRefresh: 0
    property bool refreshing: false

    readonly property int cacheMs: 5000

    function refresh() {
        if (refreshing)
            return;
        refreshing = true;
        // A callback that never lands would otherwise leave the guard stuck and
        // freeze the cache for the life of the instance.
        refreshWatchdog.restart();
        const pins = pluginService?.loadPluginState(stateId, "pins", {}) ?? {};
        Proc.runCommand("chromaThemes.list", ["@themeList@", JSON.stringify(pins)], (stdout, exitCode) => {
            refreshWatchdog.stop();
            refreshing = false;
            lastRefresh = Date.now();
            if (exitCode !== 0) {
                console.warn("chromaThemes: theme list failed with exit code", exitCode);
                return;
            }
            try {
                const data = JSON.parse(stdout);
                activeTheme = data.active || "";
                themes = data.themes || [];
                itemsChanged();
            } catch (e) {
                console.warn("chromaThemes: could not parse theme list:", e);
            }
        }, 0);
    }

    function _itemFor(theme) {
        return {
            "name": theme.name,
            "icon": "material:palette",
            "comment": theme.name === activeTheme ? "Active theme" : "Chroma theme",
            "action": "theme:" + theme.name,
            "categories": ["Chroma"],
            "imageUrl": theme.wallpaper ? "file://" + encodeURI(theme.wallpaper) : ""
        };
    }

    function getItems(query) {
        if (!refreshing && (themes.length === 0 || Date.now() - lastRefresh > cacheMs))
            refresh();

        const q = query ? query.toLowerCase().trim() : "";
        const matching = q.length === 0 ? themes : themes.filter(t => t.name.toLowerCase().includes(q));
        return matching.map(t => _itemFor(t));
    }

    function executeItem(item) {
        if (!item?.action)
            return;
        const parts = item.action.split(":");
        if (parts[0] !== "theme")
            return;

        const name = parts.slice(1).join(":");
        if (name === activeTheme)
            return;

        Quickshell.execDetached(["@chromactl@", "activate-theme", name]);
        // Reflected locally so the list reads correctly before chroma has
        // finished activating; the next refresh confirms it.
        activeTheme = name;
        itemsChanged();
        if (typeof ToastService !== "undefined")
            ToastService.showInfo("Chroma", name);
    }

    property var refreshWatchdog: Timer {
        interval: 5000
        repeat: false
        onTriggered: {
            console.warn("chromaThemes: theme list did not return, allowing another attempt");
            root.refreshing = false;
        }
    }

    Component.onCompleted: root.refresh()
}
