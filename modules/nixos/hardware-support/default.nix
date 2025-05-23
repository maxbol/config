{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.hardware-support";
  submodules = ["magic-mouse" "zsa-keyboard"];
}
