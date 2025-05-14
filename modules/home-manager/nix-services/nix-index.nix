{
  lib-mine,
  pkgs,
  vendor,
  ...
}:
lib-mine.mkFeature "features.nix-services.nix-index" {
  programs.nix-index.enable = true;
  programs.nix-index.package = vendor.nix-index-database.nix-index-with-db;
  home.packages = with pkgs; [
    nix-info
    vendor.nix-index-database.comma-with-db
    vendor.nix-search-cli.default
  ];
}
