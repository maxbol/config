{
  lib-mine,
  config,
  ...
}:
lib-mine.barrelGroup {
  inherit config;
  path = "features.darwin-desktop";
  here = ./.;
  submodules = ["sketchybar"];
}
