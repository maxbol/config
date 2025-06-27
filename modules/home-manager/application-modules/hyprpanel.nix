{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.programs.hyprpanel;
in {
  options.programs.hyprpanel = with lib; {
    systemd.target = mkOption {
      type = types.str;
      default = "graphical-session.target";
    };

    themeingIntegration = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      settings =
        options.programs.hyprpanel.settings
        // {
          default = {};
        };
    };
  };

  imports = [
    (lib.mkIf (cfg.systemd.enable) {
      systemd.user.services.hyprpanel = {
        Install = {WantedBy = lib.mkForce [cfg.systemd.target];};
      };
    })
    (lib.mkIf (cfg.themeingIntegration.enable) {
      assertions = [
        {
          assertion = cfg.settings == {};
          message = "When the themeing integration is enabled for hyprpanel, settings must be set to {}";
        }
      ];
      theme-config.hyprpanel.enable = true;
      theme-config.hyprpanel.settings = cfg.themeingIntegration.settings;
    })
  ];
}
