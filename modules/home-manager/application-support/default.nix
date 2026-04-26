{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.application-support";
  submodules = ["neovim" "intellij" "obsidian" "zathura" "spotify"];
}
