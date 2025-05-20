{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop";
  submodules = ["hyprland" "waybar" "rofi" "swim" "fonts" "wlogout" "ui-toolkits" "lockscreen" "notifications"];
}
