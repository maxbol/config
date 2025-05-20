{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.desktop-config";
  submodules = ["core-desktop" "hyprland" "ui-toolkits"];
}
