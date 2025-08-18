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
    "shutdown"
    "swim"
    "ui-toolkits"
    "waybar"
    "wlogout"
    "wm"
  ];
}
