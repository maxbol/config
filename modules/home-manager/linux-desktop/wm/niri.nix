{
  config,
  lib-mine,
  lib,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.wm.niri" {
  imports = [
    origin.inputs.niri.homeModules.niri
  ];
  config = {
    systemd.user.services.xembedsniproxy = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "display windows application tray icons in system tray";
        After = ["niri.service" "graphical-session.target"];
      };

      Service = {
        ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy";
      };

      Install.WantedBy = ["niri.service"];

      Environment = {
        DISPLAY = ":0";
      };
    };

    systemd.user.services.xwayland-satellite = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "runs rootless xwayland apps";
        After = ["niri.service" "graphical-session.target"];
      };

      Service = {
        ExecStart = lib.getExe pkgs.xwayland-satellite;
      };

      Install.WantedBy = ["niri.service"];
    };

    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-unstable;
    programs.niri.settings = {
      outputs = {
        "DP-1" = {
          # mode = "preferred";
          scale = 1.25;
        };
        "eDP-2" = {
          scale = 1.25;
          transform = {
            # flipped = true;
            # rotation = 90;
          };
        };
      };
      binds = with config.lib.niri.actions; {
        "Ctrl+Shift+H".action = focus-column-or-monitor-left;
        "Ctrl+Shift+J".action = focus-window-or-workspace-down;
        "Ctrl+Shift+K".action = focus-window-or-workspace-up;
        "Ctrl+Shift+L".action = focus-column-or-monitor-right;

        "Ctrl+Alt+H".action = set-column-width "-5%";
        "Ctrl+Alt+J".action = set-window-height "+5%";
        "Ctrl+Alt+K".action = set-window-height "-5%";
        "Ctrl+Alt+L".action = set-column-width "+5%";

        "Ctrl+Alt+Period".action = switch-preset-column-width;
        "Ctrl+Alt+Comma".action = expand-column-to-available-width;
        "Ctrl+Alt+M".action = set-column-width "100%";

        "Ctrl+Mod+H".action = move-column-left-or-to-monitor-left;
        "Ctrl+Mod+J".action = move-window-down;
        "Ctrl+Mod+K".action = move-window-up;
        "Ctrl+Mod+L".action = move-column-right-or-to-monitor-right;

        "Shift+Mod+H".action = consume-or-expel-window-left;
        "Shift+Mod+J".action = move-window-down-or-to-workspace-down;
        "Shift+Mod+K".action = move-window-up-or-to-workspace-up;
        "Shift+Mod+L".action = consume-or-expel-window-right;

        "Shift+Mod+F".action = fullscreen-window;
        "Ctrl+Shift+F".action = toggle-overview;

        "Ctrl+Space".action = spawn ["rofi" "-show" "drun"];
        "Ctrl+Mod+Space".action = spawn ["1password" "--quick-access"];

        "Mod+Q".action = close-window;

        "Ctrl+Shift+T".action = spawn "kitty";
        "Ctrl+Shift+M".action = spawn "nautilus";
        "Ctrl+Shift+B".action = spawn "firefox";

        "XF86AudioMute".action = spawn ["volumecontrol.sh" "-o" "m"];
        "XF86AudioMicMute".action = spawn ["volumecontrol.sh" "-i" "m"];
        "XF86AudioLowerVolume".action = spawn ["volumecontrol.sh" "-o" "d"];
        "XF86AudioRaiseVolume".action = spawn ["volumecontrol.sh" "-o" "i"];
        "XF86AudioPlay".action = spawn ["playerctl" "play-pause"];
        "XF86AudioPause".action = spawn ["playerctl" "play-pause"];
        "XF86AudioNext".action = spawn ["playerctl" "next"];
        "XF86AudioPrev".action = spawn ["playerctl" "previous"];

        "Mod+Shift+Return".action = spawn "wlogout";
      };
      layout = {
        default-column-display = "tabbed";
        preset-column-widths = [
          {proportion = 2. / 3.;}
          {proportion = 1. / 3.;}
          {proportion = 1. / 2.;}
          {proportion = 1.;}
        ];
        preset-window-heights = [
          {proportion = 1. / 2.;}
          {proportion = 1.;}
        ];
        default-column-width = {
          proportion = 1. / 2.;
        };
      };
      input = {
        # keyboard = {
        #   xkb = {
        #     options = "caps:escape,ctrl:swap_lalt_lctl,ctrl:swap_ralt_rctl";
        #   };
        # };
        mouse = {
          natural-scroll = true;
        };
        touchpad = {
          click-method = "clickfinger";
        };
      };
      cursor = {
        size = 28;
      };
      spawn-at-startup = [
        {
          command = ["sh" "-c" "tmux setenv -g NIRI_SOCKET $NIRI_SOCKET"];
        }
        {
          command = ["1password" "--silent"];
        }
      ];
      prefer-no-csd = true;
      environment = {
        DISPLAY = ":0"; #Needed for xwayland-satellite apps
      };
    };
    home.packages = with pkgs; [xwayland-satellite];
  };
}
