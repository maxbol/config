{
  lib,
  config,
  ...
}: let
  cfg = config.features;
  batchEnable = submodules: {
    features.terminal-services = builtins.listToAttrs (map (submodule: {
        name = submodule;
        value = {
          enable = true;
        };
      })
      submodules);
  };
  submodules = [
    "shell-config"
    "terminal-config"
    "utilities-config"
  ];
in {
  options = with lib;
  with types; {
    features.terminal-services = {
      enable = mkOption {
        type = bool;
        default = false;
        example = true;
        description = ''
          Whether to enable default terminal services for this user
        '';
      };
    };
  };

  imports = [
    ./shell-config.nix
    ./terminal-config.nix
    ./utilities-config.nix
    (lib.mkIf (cfg.terminal-services.enable) (batchEnable submodules))
    # (lib.mkIf (cfg.terminal-services.enable) {
    #   features.terminal-services.shell-config.enable = true;
    # })
  ];
}
