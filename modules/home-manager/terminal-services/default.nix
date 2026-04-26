{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.terminal-services";
  submodules = [
    "shell-config"
    "terminal-config"
    "utilities-config"
  ];
}
