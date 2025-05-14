{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.application-support";
  submodules = ["neovim" "obsidian" "zathura"];
}
