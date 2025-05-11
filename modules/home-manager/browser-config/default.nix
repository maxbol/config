{
  config,
  lib,
  ...
}: let
  cfg = config.features.browser-config;
in {
  options = with lib; {
    features.browser-config = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  imports = [
    ./firefox
  ];

  config = lib.mkIf (cfg.enable) {
    features.browser-config.firefox.enable = true;
  };
}
