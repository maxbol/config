{lib-mine, ...}:
lib-mine.mkFeature "features.nix-store-tooling" {
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
  nix.gc.automatic = false;
}
