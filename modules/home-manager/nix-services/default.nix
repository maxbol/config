{
  config,
  lib,
  ...
}: let
  cfg = config.features;
  batchEnable = submodules: {
    features.nix-services = builtins.listToAttrs (map (submodule: {
        name = submodule;
        value = {
          enable = true;
        };
      })
      submodules);
  };
  submodules = [
    "direnv-config"
    "nix-index"
  ];
in {
  options = with lib; {
    features.nix-services = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf (cfg.nix-services.enable) (batchEnable submodules);

  imports = [
    ./direnv-config.nix
    ./nix-index.nix
  ];
}
