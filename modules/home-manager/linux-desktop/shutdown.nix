{
  pkgs,
  lib-mine,
  lib,
  config,
  ...
}: let
  cfg = config.features.linux-desktop.shutdown;

  targetTypes = {
    hibernate = "systemctl hibernate";
    lock-session = "loginctl lock-session";
    logout = "loginctl terminate-user \"$USER\"";
    poweroff = "systemctl poweroff";
    reboot = "systemctl reboot";
    shutdown = "systemctl shutdown";
    soft-reboot = "systemctl soft-reboot";
    suspend = "systemctl suspend";
  };

  targetType = lib.types.enum (lib.attrsets.attrNames targetTypes);

  makePackage = targets: let
    verbs = lib.strings.concatStringsSep "\n" (builtins.map (target: "  ${target}) systemctl --user start shutdownctl-${target} ;;") targets);
  in
    pkgs.writeShellScriptBin "shutdownctl" ''
      case $1 in
      ${verbs}
        *) echo "Unknown target: $1" ;;
      esac
    '';

  makeUnit = target: {
    "shutdownctl-${target}" = {
      Unit = {
        Description = "User-level control of ${target}";
        DefaultDependencies = false;
      };

      Service = {
        Type = "oneshot";
        ExecStart = targetTypes.${target};
      };
    };
  };

  makeHook = hook: {
    "shutdownctl_hook-${hook.name}" = let
      dependencyOf = builtins.map (target: "shutdownctl-${target}.service") hook.beforeTargets;
    in {
      Unit = {
        Description = "${hook.name} - User-level shutdown hook";
        Before = dependencyOf;
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${hook.execStart}";
      };

      Install.WantedBy = dependencyOf;
    };
  };

  makeUnits = builtins.foldl' (units: target: units // (makeUnit target)) {};
  makeHooks = builtins.foldl' (hooks: hook: hooks // (makeHook hook)) {};
in
  lib-mine.mkFeature "features.linux-desktop.shutdown" {
    options = with lib; {
      targets = mkOption {
        type = types.listOf targetType;
        default = lib.attrsets.attrNames targetTypes;
      };

      package = mkOption {
        type = types.package;
        default = makePackage cfg.targets;
      };

      hooks = mkOption {
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
            };
            beforeTargets = mkOption {
              type = types.listOf targetType;
              default = lib.attrsets.attrNames targetTypes;
            };
            execStart = mkOption {
              type = types.either types.str types.path;
            };
          };
        });
        default = [];
      };
    };
    config = {
      systemd.user.services = (makeUnits cfg.targets) // (makeHooks cfg.hooks);
      home.packages = [cfg.package];
    };
  }
