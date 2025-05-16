{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.darwin-desktop";
  submodules = [
    "aerospace"
    "jankyborders"
    "sketchybar"
  ];
}
