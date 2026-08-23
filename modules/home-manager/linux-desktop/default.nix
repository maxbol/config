{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop";
  submodules = [
    "default-application-handling"
    "fonts"
    "gaming"
    "launcher"
    "lockscreen"
    "notifications"
    "panel"
    "rofi"
    "shell"
    "shutdown"
    "ui-toolkits"
    "walker"
    "waybar"
    "wlogout"
    "wm"
  ];
}
