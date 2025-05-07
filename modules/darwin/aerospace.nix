{
  pkgs,
  lib,
  ...
}: let
  PATH = "/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.sketchybar}/bin:${pkgs.aerospace}/bin:${pkgs.jankyborders}/bin";
in {
  environment.systemPackages = [
    pkgs.aerospace
  ];

  launchd.user.agents.aerospace = {
    environment.PATH = PATH;
  };

  # Reasonable system settings to make Aerospace look and behave correctly
  system.defaults = {
    spaces = {
      spans-displays = true;
    };
    dock = {
      expose-group-apps = true;
    };
  };

  services.aerospace = {
    enable = true;
    settings = let
      triggerSketchybarWorkspaceChanged = [
        "/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];
    in {
      exec-on-workspace-change = triggerSketchybarWorkspaceChanged;
      on-focused-monitor-changed = [];
      gaps = {
        outer = {
          left = 20;
          right = 20;
          top = 55;
          bottom = 20;
        };
        inner = {
          horizontal = 10;
          vertical = 10;
        };
      };
      mode.main.binding = {
        alt-ctrl-shift-f = "fullscreen";
        alt-ctrl-f = "layout floating tiling";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-ctrl-h = "workspace prev";
        alt-ctrl-l = "workspace next";

        alt-shift-ctrl-h = "move-node-to-workspace prev --focus-follows-window";
        alt-shift-ctrl-l = "move-node-to-workspace next --focus-follows-window";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-left = "join-with left";
        alt-right = "join-with right";
        alt-up = "join-with up";
        alt-down = "join-with down";

        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";

        alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
        alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
        alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
        alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
      };
    };
  };
}
