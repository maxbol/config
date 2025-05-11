{
  pkgs,
  config,
  lib,
  origin,
  ...
}: let
  inherit (origin.config.meta) flakeRoot;
  secretPath = flakeRoot + "/secrets/hosts/${config.networking.hostName}";
  cfg = config.features.secrets-management;
in {
  options = with lib; {
    features.secrets-management = mkOption {
      type = types.bool;
      default = false;
    };
  };

  imports = [
    origin.inputs.sops-nix.nixosModules.sops
  ];

  config = lib.mkIf (cfg.enable) {
    sops = {
      defaultSopsFile = secretPath + "/default.yaml";
    };

    environment.systemPackages = with pkgs; [
      sops
    ];
  };
}
