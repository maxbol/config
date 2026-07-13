{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  submodules = ["firefox" "helium" "google-chrome"];
  path = "features.browser-config";
}
