{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.custom-udev-rules";
  submodules = ["zsa-keyboard"];
}
