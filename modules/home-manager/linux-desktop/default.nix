{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop";
  submodules = [
    "default-application-handling"
    "fonts"
    "gaming"
    "lockscreen"
    "notifications"
    "panel"
    "rofi"
    "shell"
    "shutdown"
    "swim"
    "ui-toolkits"
    "walker"
    "waybar"
    "wlogout"
    "wm"
  ];
}
