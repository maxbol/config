import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    // State is keyed by hand rather than through the injected pluginId: the
    // launcher surface is created without one, and both surfaces have to read
    // and write the same pins.
    readonly property string stateId: "chromaThemes"

    // Chroma rewrites dms's own customThemeFile on every theme activation and
    // that path carries the theme name, so it doubles as the theme-changed
    // signal. Watching the chroma directory instead would not work: `active`
    // is a symlink into the immutable store, so inotify would end up pinned to
    // a path that never changes again.
    readonly property string currentTheme: {
        const file = SettingsData.customThemeFile || "";
        if (!file)
            return "";
        const parts = file.split("/");
        return parts.length >= 2 ? parts[parts.length - 2] : "";
    }

    // Set while we apply a pin ourselves, so restoring does not immediately
    // get recorded as a fresh choice.
    property bool applying: false

    function pins() {
        return pluginService?.loadPluginState(stateId, "pins", {}) ?? {};
    }

    function remember() {
        if (applying || SessionData.perMonitorWallpaper)
            return;

        const theme = currentTheme;
        const wallpaper = SessionData.wallpaperPath || "";
        if (!theme || !wallpaper)
            return;

        const current = pins();
        if (current[theme] === wallpaper)
            return;

        current[theme] = wallpaper;
        pluginService?.savePluginState(stateId, "pins", current);
    }

    function restore(theme) {
        if (!theme || SessionData.perMonitorWallpaper)
            return;

        const pinned = pins()[theme];
        if (!pinned)
            return;

        // The helper resolves the pin against the theme's own wallpapers, so a
        // pin still works after a rebuild moved the theme's store path.
        Proc.runCommand("chromaThemes.resolve", ["@themeList@", JSON.stringify(pins())], (stdout, exitCode) => {
            if (exitCode !== 0)
                return;
            try {
                const data = JSON.parse(stdout);
                const entry = (data.themes || []).find(t => t.name === theme);
                const wallpaper = entry?.wallpaper || "";
                if (!wallpaper || wallpaper === SessionData.wallpaperPath)
                    return;
                root.applying = true;
                SessionData.setWallpaper(wallpaper);
                applyGuard.restart();
            } catch (e) {
                console.warn("chromaThemes: could not resolve the pinned wallpaper:", e);
            }
        }, 0);
    }

    Timer {
        id: applyGuard
        interval: 1000
        onTriggered: root.applying = false
    }

    onCurrentThemeChanged: root.restore(currentTheme)

    Connections {
        target: SessionData
        function onWallpaperPathChanged() {
            root.remember();
        }
    }

    Component.onCompleted: {
        // Re-assert the pin in case the wallpaper changed while dms was down,
        // and record one for a theme that has never been pinned so that
        // switching away and back keeps the current wallpaper.
        if (pins()[currentTheme])
            root.restore(currentTheme);
        else
            root.remember();
    }
}
