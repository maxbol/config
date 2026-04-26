{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  submodules = ["firefox" "google-chrome"];
  path = "features.browser-config";
}
