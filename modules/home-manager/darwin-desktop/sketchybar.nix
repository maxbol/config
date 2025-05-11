{
  config,
  lib,
  ...
}: let
  cfg = config.features.darwin-desktop.sketchybar;
in {
  options = with lib; {
    features.darwin-desktop.sketchybar = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    impure-config-management.config."sketchybar/sketchybarrc" = "config/sketchybar/sketchybarrc";
    impure-config-management.config."sketchybar/plugins" = "config/sketchybar/plugins";
  };
}
