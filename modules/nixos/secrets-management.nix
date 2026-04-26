{
  pkgs,
  config,
  lib-mine,
  origin,
  ...
}: let
  inherit (origin.config.meta) flakeRoot;
  secretPath = flakeRoot + "/secrets/hosts/${config.networking.hostName}";
in
  lib-mine.mkFeature "features.secrets-management" {
    imports = [
      origin.inputs.sops-nix.nixosModules.sops
    ];

    config = {
      sops = {
        defaultSopsFile = secretPath + "/default.yaml";
      };

      environment.systemPackages = with pkgs; [
        sops
      ];
    };
  }
