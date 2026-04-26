{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.nix-services";
  submodules = ["direnv-config" "nix-index"];
}
