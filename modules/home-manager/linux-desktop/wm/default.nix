{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.linux-desktop.wm";
  submodules = ["hyprland" "niri"];
}
