{
  lib-mine,
  pkgs,
  origin,
  config,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.panel" {
  imports = [
    origin.inputs.hyprpanel.homeManagerModules.hyprpanel
  ];

  config = {
    home.packages = with pkgs; [
      brightnessctl
      grimblast
      wf-recorder
      hyprpicker
      hyprsunset
      btop
      htop
    ];

    programs.hyprpanel = {
      enable = true;
      config.enable = false;
      themeingIntegration.enable = true;

      settings = {
        bar.clock = {
          format = "%a %b %d  %H:%M";
        };
        menus.dashboard = {
          powermenu = {
            avatar.image = "${config.identity.userImage}";
          };
        };
        layout = {
          "bar.layouts" = {
            "*" = {
              left = ["dashboard" "workspaces" "windowtitle"];
              middle = ["media"];
              right = ["volume" "network" "bluetooth" "battery" "systray" "clock" "notifications"];
            };
          };
        };
        menus.clock = {
          time = {
            military = true;
            hideSeconds = true;
          };
          weather = {
            location = "Gothenburg, Sweden";
            unit = "metric";
          };
        };
        theme.font = {
          name = "Iosevka";
          size = "14px";
        };
        terminal = "$TERMINAL";

        theme.bar.transparent = true;

        wallpaper.enable = false;
      };
    };

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
      Install = {WantedBy = ["hyprland-session.target"];};
    };
  };
}
