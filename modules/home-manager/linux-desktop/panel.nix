{
  lib-mine,
  pkgs,
  origin,
  config,
  self,
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
        bar.launcher = {
          icon = "";
        };
        menus.dashboard = {
          powermenu = {
            avatar.image = "${config.identity.userImage}";

            logout = "shutdownctl logout";
            reboot = "shutdownctl reboot";
            shutdown = "shutdownctl poweroff";
            sleep = "shutdownctl suspend";
          };
          shortcuts = {
            left = {
              shortcut1 = {
                command = "uwsm app -- firefox";
                icon = "󰈹";
                tooltip = "Firefox";
              };
              shortcut2 = {
                command = "uwsm app -- kitty";
                icon = "󰄛";
                tooltip = "Kitty";
              };
              shortcut3 = {
                command = "uwsm app -- slack";
                icon = "󰒱";
                tooltip = "Slack";
              };
            };
            right = {
              shortcut3 = {
                command = "uwsm app -- ${self.misc-scripts-hyprdots}/bin/screenshot.sh sf";
                icon = "󰄀";
                tooltip = "Screenshot";
              };
            };
          };
        };
        layout = {
          "bar.layouts" = {
            "*" = {
              left = ["dashboard" "workspaces" "windowtitle"];
              middle = ["media"];
              right = ["volume" "network" "bluetooth" "battery" "systray" "clock" "hypridle" "notifications"];
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
        scalingPriority = "hyprland";
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
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.hyprpanel}/bin/hyprpanel";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };
    };
  };
}
