{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop";
  submodules = [
    "fonts"
    "gaming"
    "lockscreen"
    "panel"
    "rofi"
    "shutdown"
    "swim"
    "ui-toolkits"
    "wlogout"
    "wm"
    /*
    "notifications"
    */
  ];
}
