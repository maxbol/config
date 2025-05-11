{
  pkgs,
  config,
  lib,
  vendor,
  ...
}: let
  cfg = config.features;
in {
  options = with lib; {
    features.nix-services.nix-index = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf (cfg.nix-services.nix-index.enable) {
    programs.nix-index.enable = true;
    programs.nix-index.package = vendor.nix-index-database.nix-index-with-db;
    home.packages = with pkgs; [
      nix-info
      vendor.nix-index-database.comma-with-db
      vendor.nix-search-cli.default
    ];
  };
}
