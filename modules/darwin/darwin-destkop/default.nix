{
  config,
  lib,
  ...
}: let
  cfg = config.features.darwin-desktop;
  batchEnable = submodules: {
    features.darwin-desktop = builtins.listToAttrs (map (submodule: {
        name = submodule;
        value = {
          enable = true;
        };
      })
      submodules);
  };
  submodules = [
    "aerospace"
    "jankyborders"
    "sketchybar"
  ];
in {
  options = with lib; {
    features.darwin-desktop = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  imports = [
    ./aerospace.nix
    ./jankyborders.nix
    ./sketchybar.nix
  ];

  config = lib.mkIf (cfg.enable) (batchEnable submodules);
}
