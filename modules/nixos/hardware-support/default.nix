{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.hardware-support";
  submodules = ["magic-mouse" "qmk-bootloader"];
}
