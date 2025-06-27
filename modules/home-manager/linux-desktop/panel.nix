{
  lib,
  lib-mine,
  pkgs,
  config,
  self,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.panel" {
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
      systemd.enable = true;
      systemd.target = "hyprland-session.target";

      settings = lib.mkForce {}; # Do not configure directly, rather use the themeing integration

      themeingIntegration = {
        enable = true;

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
                left = [
                  "dashboard"
                  /*
                  "workspaces"
                  */
                  "windowtitle"
                ];
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
            name = "Aporetic Sans Mono";
            size = "14px";
          };
          terminal = "$TERMINAL";

          theme.bar.transparent = true;

          wallpaper.enable = false;
        };
      };
    };
  };
}
