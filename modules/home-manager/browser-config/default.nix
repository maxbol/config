{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  submodules = ["firefox"];
  path = "features.browser-config";
}
