{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop";
  submodules = [
    "connect"
    "default-application-handling"
    "fonts"
    "gaming"
    "launcher"
    "lockscreen"
    "notifications"
    "panel"
    "shell"
    "shutdown"
    "ui-toolkits"
    "walker"
    "waybar"
    "wlogout"
    "wm"
  ];
}
