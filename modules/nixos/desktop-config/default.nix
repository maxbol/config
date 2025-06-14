{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.desktop-config";
  submodules = ["appimage" "core-desktop" "flatpak" "hyprland" "niri" "ui-toolkits"];
}
