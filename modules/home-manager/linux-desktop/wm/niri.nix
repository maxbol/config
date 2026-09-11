{
  config,
  lib-mine,
  lib,
  origin,
  pkgs,
  self,
  ...
}: let
  dms-ipc = call: config.lib.niri.actions.spawn (["dms" "ipc" "call"] ++ call);

  doubletapServer = pkgs.writeShellScript "doubletap-server" ''
    export TMPDIR=''${TMPDIR:-/run/user/$UID}
    SOCKET_PATH="$TMPDIR/doubletap.sock"
    TAP_THRESHOLD=''${TAP_THRESHOLD:-1000}  # Default 500ms if not set
    last_tap_time=0  # Store last tap timestamp in memory

    # Clean up on exit
    cleanup() {
      rm -f "$SOCKET_PATH"
      exit 1
    }
    trap cleanup EXIT INT TERM

    # Remove existing socket
    rm -f "$SOCKET_PATH"

    # Start the server
    while true; do
      ${pkgs.libressl.nc}/bin/nc -lUk "$SOCKET_PATH" | while read -r message; do
        if [ "$message" = "doubletap" ]; then
          current_time=$(date +%s%3N)  # Current time in milliseconds
          time_diff=$((current_time - last_tap_time))

          if [ "$last_tap_time" -ne 0 ] && [ "$time_diff" -lt "$TAP_THRESHOLD" ]; then
            # Double tap detected - toggle overview
            ${pkgs.niri-unstable}/bin/niri msg action toggle-overview
            last_tap_time=0  # Reset timestamp after successful double tap
          else
            # First tap or too much time passed - store current time
            last_tap_time=$current_time
          fi
        fi
      done
    done
  '';

  doubletapClient = pkgs.writeShellScript "doubletap-client" ''
    export TMPDIR=''${TMPDIR:-/run/user/$UID}
    SOCKET_PATH="$TMPDIR/doubletap.sock"

    # Send doubletap message to server
    echo "doubletap" | ${pkgs.libressl.nc}/bin/nc -UN "$SOCKET_PATH"
  '';

  # DMS has no keyboard layout OSD (upstream feature request #1351), so watch
  # niri's event stream (which reports layout changes from xkb grp: toggles as
  # well as switch-layout actions) and surface them as DMS toasts. NIRI_SOCKET
  # comes from the systemd user manager environment, which niri --session
  # populates via import-environment (same mechanism dms.service relies on).
  #
  # niri's IPC only reports xkb display names ("Swedish"), not layout codes,
  # but the codes are the index-order of this string, which is defined once
  # here and used for input.keyboard.xkb.layout as well.
  xkbLayouts = "us,se";

  layoutOsdWatcher = pkgs.writeShellScript "layout-osd-watcher" ''
    IFS=',' read -r -a codes <<< "${xkbLayouts}"
    while IFS= read -r line; do
      case "$line" in
        *"Keyboard layout switched"*)
          idx=''${line##*: }
          dms ipc call toast infoWith "Keyboard layout: ''${codes[$idx]:-$idx}" "" "" kblayout
          ;;
      esac
    done < <(${pkgs.niri-unstable}/bin/niri msg event-stream)
  '';
in
  lib-mine.mkFeature "features.linux-desktop.wm.niri" {
    imports = [
      origin.inputs.niri.homeModules.niri
    ];

    config = {
      systemd.user.services.niri-layout-osd = {
        Unit = {
          Description = "DMS toast on niri keyboard layout change";
          PartOf = [config.wayland.systemd.target];
          After = [config.wayland.systemd.target];
        };

        Service = {
          # "always" rather than "on-failure": the event stream read returns
          # cleanly (exit 0) whenever niri exits, but the watcher must come
          # back with the next session.
          Restart = "always";
          RestartSec = "2s";
          ExecStart = "${layoutOsdWatcher}";
          # The script resolves `dms` here; niri is referenced by store path.
          # /run/current-system/sw/bin is needed for the coreutils used by the
          # script, which the systemd user manager env does not provide.
          Environment = "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
        };

        Install.WantedBy = [config.wayland.systemd.target];
      };

      systemd.user.services.xwayland-env-init = {
        Unit = {
          Before = ["app-org.kde.xwaylandvideobridge@autostart.service"];
        };

        Service = {
          Type = "oneshot";
          ExecStart = let
            pathWrap = cmd:
              pkgs.writeShellScript "xwayland-env-init.sh" ''
                export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
                ${cmd}
              '';
          in
            pathWrap "systemctl --user import-environment DISPLAY PATH WAYLAND_DISPLAY";
          Environment = [
            "DISPLAY=:0"
            "WAYLAND_DISPLAY=wayland-1"
          ];
        };

        Install.WantedBy = ["niri.service"];
      };

      systemd.user.services.xembedsniproxy = {
        Unit = {
          ConditionEnvironment = ["WAYLAND_DISPLAY" "DISPLAY"];
          Description = "display windows application tray icons in system tray";
          After = ["niri.service" "xwayland-satellite.service" "graphical-session.target"];
        };

        Service = {
          ExecStart = "${lib.getExe pkgs.zsh} -c \"${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy\"";
          Restart = "on-failure";
          Environment = [
            "DISPLAY=:0"
            "PATH=${config.home.profileDirectory}/bin"
          ];
        };

        Install.WantedBy = ["niri.service"];
      };

      systemd.user.services.xwayland-satellite = {
        Unit = {
          ConditionEnvironment = ["WAYLAND_DISPLAY" "DISPLAY"];
          Description = "runs rootless xwayland apps";
          After = ["niri.service" "xwayland-env-init.service" "graphical-session.target"];
        };

        Service = {
          ExecStart = lib.getExe self.xwayland-satellite-fix;
        };

        Install.WantedBy = ["niri.service"];
      };

      # systemd.user.services.gvfs-nautilus-prewarm = {
      #   Unit = {
      #     Description = "pre-activate gvfs daemons and warm nautilus for fast cold start";
      #     After = ["niri.service"];
      #   };
      #
      #   Service = {
      #     Type = "oneshot";
      #     ExecStart = let
      #       warmup = pkgs.writeShellScript "gvfs-nautilus-prewarm.sh" ''
      #         export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
      #         gio mount -l 2>&1 || true
      #         nautilus -q 2>&1 || true
      #       '';
      #     in
      #       warmup;
      #   };
      #
      #   Install.WantedBy = ["niri.service"];
      # };

      # systemd.user.services.nautilus-keepwarm = {
      #   Unit = {
      #     Description = "pin nautilus and its libraries in memory for instant cold start";
      #     After = ["gvfs-nautilus-prewarm.service"];
      #   };
      #
      #   Service = {
      #     Type = "simple";
      #     LimitMEMLOCK = "512M";
      #     ExecStart = let
      #       keepwarm = pkgs.writeShellScript "nautilus-keepwarm.sh" ''
      #         export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
      #         bin=$(dirname "$(readlink -f "$(command -v nautilus)")")/.nautilus-wrapped
      #         libs=$(ldd "$bin" | awk '$3 ~ /^\// {print $3}' | sort -u)
      #         exec ${pkgs.vmtouch}/bin/vmtouch -l -f "$bin" $libs /run/opengl-driver/lib/libvulkan_asahi.so
      #       '';
      #     in
      #       keepwarm;
      #     Restart = "on-failure";
      #     RestartSec = "30s";
      #   };
      #
      #   Install.WantedBy = ["niri.service"];
      # };

      systemd.user.services.doubletap-server = {
        Unit = {
          Description = "doubletap detection server for niri";
          After = ["niri.service"];
        };

        Service = {
          ExecStart = doubletapServer;
          Restart = "on-failure";
          Environment = [
            "TAP_THRESHOLD=1000"
          ];
        };

        Install.WantedBy = ["niri.service"];
      };

      programs.niri.enable = true;
      programs.niri.package = pkgs.niri-unstable;

      # services.kanshi = {
      #   enable = true;
      #   systemdTarget = "niri.service";
      #   profiles = {
      #     backDocked = {
      #       exec = "${self.swimctl}/bin/swimctl activate";
      #       outputs = [
      #         {
      #           criteria = "eDP-2";
      #         }
      #         {
      #           criteria = "DP-1";
      #         }
      #       ];
      #     };
      #     sideDocked = {
      #       exec = "${self.swimctl}/bin/swimctl activate";
      #       outputs = [
      #         {
      #           criteria = "eDP-2";
      #         }
      #         {
      #           criteria = "DP-3";
      #         }
      #       ];
      #     };
      #     dp4Docked = {
      #       exec = "${self.swimctl}/bin/swimctl activate";
      #       outputs = [
      #         {
      #           criteria = "eDP-2";
      #         }
      #         {
      #           criteria = "DP-4";
      #         }
      #       ];
      #     };
      #   };
      # };

      theme-config.niri.baseConfig = {
        # outputs = {
        #   "DP-1" = {
        #     # mode = "preferred";
        #     scale = 1.25;
        #     position = {
        #       x = 2048;
        #       y = 0;
        #     };
        #   };
        #   "DP-3" = {
        #     variable-refresh-rate = true;
        #     # mode = "preferred";
        #     scale = 1.25;
        #     position = {
        #       x = 2048;
        #       y = 0;
        #     };
        #   };
        #   "DP-4" = {
        #     variable-refresh-rate = true;
        #     # mode = "preferred";
        #     scale = 1.25;
        #     position = {
        #       x = 2048;
        #       y = 0;
        #     };
        #   };
        #   "eDP-2" = {
        #     scale = 1.25;
        #     position = {
        #       x = 0;
        #       y = 0;
        #     };
        #     transform = {
        #       # flipped = true;
        #       # rotation = 90;
        #     };
        #   };
        # };
        binds = with config.lib.niri.actions; {
          # "Ctrl+Space".action = dms-ipc ["spotlight-bar" "toggle"];
          "Shift+Mod+V".action = dms-ipc ["clipboard" "toggle"];
          "Ctrl+Shift+O".action = dms-ipc ["tmux" "toggle"];
          "XF86AudioLowerVolume".action = dms-ipc ["audio" "decrement" "3"];
          "XF86AudioRaiseVolume".action = dms-ipc ["audio" "increment" "3"];
          "XF86AudioMute".action = dms-ipc ["audio" "mute"];
          "XF86MonBrightnessUp".action = dms-ipc ["brightness" "increment" "5" ""];
          "XF86MonBrightnessDown".action = dms-ipc ["brightness" "decrement" "5" ""];

          "Ctrl+Shift+H".action = focus-column-or-monitor-left {skip-animation = false;};
          "Ctrl+Shift+J".action = focus-window-or-workspace-down {skip-animation = false;};
          "Ctrl+Shift+K".action = focus-window-or-workspace-up {skip-animation = false;};
          "Ctrl+Shift+L".action = focus-column-or-monitor-right {skip-animation = false;};

          "Ctrl+Alt+H".action = set-column-width "-5%";
          "Ctrl+Alt+J".action = set-window-height "+5%";
          "Ctrl+Alt+K".action = set-window-height "-5%";
          "Ctrl+Alt+L".action = set-column-width "+5%";

          "Ctrl+Alt+Period".action = set-column-width "100%";
          "Ctrl+Alt+Comma".action = set-column-width "50%";
          "Ctrl+Alt+M".action = switch-preset-column-width;

          "Ctrl+Shift+Period".action = focus-floating;
          "Ctrl+Shift+Comma".action = focus-tiling;
          "Ctrl+Shift+Slash".action = toggle-window-floating;

          "Ctrl+Mod+H".action = move-column-left-or-to-monitor-left;
          "Ctrl+Mod+J".action = move-window-down-or-to-workspace-down;
          "Ctrl+Mod+K".action = move-window-up-or-to-workspace-up;
          "Ctrl+Mod+L".action = move-column-right-or-to-monitor-right;

          "Shift+Mod+H".action = consume-or-expel-window-left;
          "Shift+Mod+J".action = move-window-down-or-to-workspace-down;
          "Shift+Mod+K".action = move-window-up-or-to-workspace-up;
          "Shift+Mod+L".action = consume-or-expel-window-right;

          "Ctrl+Shift+Mod+H".action = focus-monitor-left;
          "Ctrl+Shift+Mod+L".action = focus-monitor-right;

          "Ctrl+Alt+Shift+H".action = move-window-to-monitor-left;
          "Ctrl+Alt+Shift+L".action = move-window-to-monitor-right;

          "Shift+Mod+F".action = fullscreen-window;
          "Ctrl+Up".action = toggle-overview;

          # "Ctrl+Space".action = noctalia-ipc-call ["launcher" "toggle"];
          # "Ctrl+Space".action = spawn ["${self.rofi-launchers-hyprdots}/bin/rofilaunch.sh" "d"];
          "Ctrl+Space".action = spawn ["vicinae" "toggle"];
          "Ctrl+Mod+Space".action = spawn ["1password" "--quick-access"];

          "Mod+Q".action = close-window;

          "Ctrl+Shift+T".action = spawn "kitty";
          "Ctrl+Alt+T".action = spawn ["kitty" "bash"];
          "Ctrl+Shift+F".action = spawn "nautilus";
          "Ctrl+Shift+B".action = spawn "helium";

          "Shift+Mod+B".action = spawn ["kitty" "--app-id" "bluetui" "bluetui"];
          "Ctrl+Mod+N".action = spawn ["kitty" "--app-id" "impala" "impala"];

          "Ctrl+Shift+P".action.screenshot = [{show-pointer = false;}];
          "Ctrl+Shift+Alt+P".action.screenshot-window = [{write-to-disk = true;}];
          "Ctrl+Shift+Mod+P".action.screenshot-screen = [{write-to-disk = true;}];

          "Shift+Mod+W".action = dms-ipc ["dankdash" "wallpaper"];
          # "Shift+Mod+W".action = spawn ["${self.rofi-launchers-hyprdots}/bin/rofilaunch.sh" "w"];
          # "Shift+Mod+E".action = spawn ["${self.rofi-launchers-hyprdots}/bin/rofilaunch.sh" "f"];
          # "Shift+Mod+R".action = spawn "${self.rofi-launchers-hyprdots}/bin/rofiselect.sh";
          "Shift+Mod+T".action = dms-ipc ["spotlight" "toggleQuery" "#theme "];
          # "Shift+Mod+V".action = spawn ["${self.rofi-launchers-hyprdots}/bin/cliphist.sh" "c"];
          # "Shift+Mod+V".action = noctalia-ipc-call ["launcher" "clipboard"];
          # "Shift+Mod+V".action = spawn ["vicinae" "vicinae://extensions/vicinae/clipboard/history"];
          "Shift+Mod+C".action = center-window;

          "Shift+Mod+A".action = set-dynamic-cast-window;
          "Shift+Mod+S".action = set-dynamic-cast-monitor;

          "Shift+Mod+D".action = spawn ["pkill" "-SIGUSR1" "wayscriber"];

          "Shift+Mod+M".action = toggle-column-tabbed-display;

          # "XF86AudioMute".action = noctalia-ipc-call ["volume" "muteOutput"];
          # "XF86AudioMicMute".action = noctalia-ipc-call ["volume" "muteInput"];
          # "XF86AudioMute".action = spawn ["volumecontrol.sh" "-o" "m"];
          # "XF86AudioMicMute".action = spawn ["volumecontrol.sh" "-i" "m"];
          # "XF86AudioLowerVolume".action = noctalia-ipc-call ["volume" "decrease"];
          # "XF86AudioRaiseVolume".action = noctalia-ipc-call ["volume" "increase"];
          # "XF86AudioLowerVolume".action = spawn ["volumecontrol.sh" "-o" "d"];
          # "XF86AudioRaiseVolume".action = spawn ["volumecontrol.sh" "-o" "i"];
          "XF86AudioPlay".action = spawn ["playerctl" "play-pause"];
          "XF86AudioPause".action = spawn ["playerctl" "play-pause"];
          "XF86AudioNext".action = spawn ["playerctl" "next"];
          "XF86AudioPrev".action = spawn ["playerctl" "previous"];

          "Mod+Shift+Return".action = dms-ipc ["powermenu" "toggle"];

          "MouseMiddle".action = spawn "${doubletapClient}";
        };
        overview = {
          workspace-shadow = {
            enable = false;
          };
        };
        layout = {
          default-column-display = "tabbed";
          # default-column-display = "normal";
          background-color = "transparent";

          # Gaps and border/focus-ring widths are managed by dms (through the
          # dms/*.kdl includes), their colors by the Chroma theme.kdl include.
          # border.enable = false;
          # focus-ring.enable = false;

          tab-indicator = {
            hide-when-single-tab = true;
            position = "left";
            gap = -8;
          };

          preset-column-widths = [
            {proportion = 1.;}
            {proportion = 2. / 3.;}
            {proportion = 1. / 3.;}
            {proportion = 1. / 2.;}
          ];
          preset-window-heights = [
            {proportion = 1. / 2.;}
            {proportion = 1.;}
          ];
          default-column-width = {
            proportion = 1. / 2.;
          };
        };
        layer-rules = [
          {
            matches = [
              {
                namespace = "swaync-control-center";
              }
            ];
          }
          {
            matches = [
              {
                namespace = "quickshell";
              }
              {
                namespace = "swww-daemon";
              }
              {
                namespace = "noctalia-wallpaper";
              }
            ];
            place-within-backdrop = true;
          }
        ];
        window-rules = [
          {
            geometry-corner-radius = let
              # radius = 10.;
              radius = 0.0;
            in {
              bottom-left = radius;
              bottom-right = radius;
              top-left = radius;
              top-right = radius;
            };
            clip-to-geometry = true;
            draw-border-with-background = false;
          }
          # {
          #   matches = [
          #     {
          #       is-focused = false;
          #       app-id = "kitty";
          #     }
          #   ];
          #   opacity = 0.9;
          # }
          {
            matches = [
              {
                app-id = "^org\.gnome\.";
              }
            ];
            draw-border-with-background = false;
          }
          {
            matches = [
              {
                app-id = "org.quickshell$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              {
                app-id = ".blueman-manager-wrapped";
              }
              {
                app-id = "org.stronnag.wayfarer";
              }
              {
                app-id = "org.pulseaudio.pavucontrol";
              }
              {
                app-id = "bluetui";
              }
              {
                app-id = "wdisplays";
              }
              {
                app-id = "impala";
              }
              {
                app-id = "org.gnome.FileRoller";
              }
              {
                app-id = "org.gnome.Nautilus";
              }
              {
                app-id = "io.github.celluloid_player.Celluloid";
              }
              {
                app-id = "org.libvips.vipsdisp";
              }
              {
                app-id = "Bitwarden";
              }
              {
                app-id = "1password";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              {
                app-id = "bluetui";
              }
              {
                app-id = "impala";
              }
            ];
            default-window-height.proportion = 2. / 3.;
            default-column-width.proportion = 2. / 3.;
          }
          {
            matches = [
              {
                is-floating = true;
              }
            ];
            tiled-state = false;
          }
          {
            matches = [
              {
                app-id = "xwaylandvideobridge";
              }
            ];
            opacity = 0.0;
            max-width = 1;
            max-height = 1;
            open-floating = true;
            open-focused = false;
            focus-ring.enable = false;
            border.enable = false;
            shadow.enable = false;
            # block-out-from = "screencast";
            tiled-state = false;
          }
          # Make windows translucent unless they are both active and focused.
          {
            matches = [
              {
                app-id = "kitty";
                is-focused = true;
              }
            ];
            excludes = [
              {
                is-active = true;
              }
            ];
            opacity = 0.99;
          }
          {
            matches = [
              {
                app-id = "kitty";
              }
            ];
            excludes = [
              {
                is-active = true;
              }
              {
                is-focused = true;
              }
            ];
            opacity = 0.95;
          }
        ];
        input = {
          keyboard = {
            xkb = {
              layout = xkbLayouts;
              options = "grp:shift_caps_toggle";
            };
          };
          mouse = {
            accel-speed = -0.6;
            natural-scroll = true;
            scroll-factor = 2.0;
          };
          touchpad = {
            accel-speed = 0.7;
            click-method = "clickfinger";
            middle-emulation = false;
          };
        };
        cursor = {
          theme = "macOS";
          size = 28;
        };
        spawn-at-startup = [
          {
            command = ["sh" "-c" "tmux setenv -g NIRI_SOCKET $NIRI_SOCKET"];
          }
          {
            command = ["1password" "--silent"];
          }
          {
            command = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"];
          }
          {
            command = ["wl-paste" "--type" "image" "--watch" "cliphist" "store"];
          }
          {
            command = ["sh" "-c" "sleep 2s && ~/.nix-profile/bin/wayscriber --daemon"];
          }
        ];
        hotkey-overlay = {
          skip-at-startup = true;
        };
        clipboard.disable-primary = true;
        prefer-no-csd = true;
        environment = {
          DISPLAY = ":0"; #Needed for xwayland-satellite apps
        };
      };

      theme-config.niri.extraConfigTxt = ''
        include "dms/alttab.kdl"
        include "dms/binds.kdl"
        include "dms/colors.kdl"
        include "dms/cursor.kdl"
        include "dms/layout.kdl"
        include "dms/outputs.kdl"
        include "dms/windowrules.kdl"
        include "dms/wpblur.kdl"

        recent-windows {
          binds {
            Mod+Tab { next-window; }
            Mod+Shift+Tab { previous-window; }

            Mod+Backspace { next-window filter="app-id"; }
            Mod+Shift+Backspace { previous-window filter="app-id"; }
          }
        }

        window-rule {
          match is-floating=false
          background-effect {
            blur true
            xray false
          }
        }

        // niri-flake does not know this property yet, so it cannot go into
        // the typed baseConfig window-rules.
        window-rule {
          on-xdg-activate "focus"
        }
      '';

      services.network-manager-applet.enable = true;
      services.blueman-applet.enable = true;
      services.playerctld.enable = true;

      home.packages = with pkgs; [
        bluetui
        brightnessctl
        cliphist
        gpu-screen-recorder
        impala
        kdePackages.plasma-workspace # necessary for xembedsniproxy, to get wine tray into hyprpanel
        playerctl
        procps
        swappy
        wl-clipboard
        wl-clipboard-x11
        quickshell
      ];
    };
  }
