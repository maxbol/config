{
  pkgs,
  lib,
  config,
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
    };
  };

  imports = [
    (lib.mkIf (cfg.systemd.enable) {
      systemd.user.services.hyprpanel = {
        Unit = {
          Description = "A Bar/Panel for Hyprland with extensive customizability.";
          Documentation = "https://hyprpanel.com";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session-pre.target"];
        };
        Service = {
          ExecStart = "${pkgs.hyprpanel}/bin/hyprpanel";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };
        Install = {WantedBy = [cfg.systemd.target];};
      };
    })
    (lib.mkIf (cfg.themeingIntegration.enable) {
      assertions = [
        {
          assertion = !cfg.config.enable;
          message = "When the themeing integration is enabled for hyprpanel, regular config generation via config.enable must be disabled";
        }
      ];
      theme-config.hyprpanel.enable = true;
    })
  ];
}
