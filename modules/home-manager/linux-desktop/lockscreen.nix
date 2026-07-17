{
  config,
  lib,
  lib-mine,
  pkgs,
  ...
}: let
  suspendEnabled = true;

  # dms replaces the previous hyprlock/hypridle pair: it ships its own
  # ext-session-lock lock screen and a built-in idle service with monitor-off,
  # lock and suspend timers (per power source). Timeouts are in seconds and 0
  # disables the respective action. The lock screen can also be triggered
  # manually with `loginctl lock-session` or `dms ipc call lock lock`.
  dmsIdleSettings =
    {
      acLockTimeout = 300;
      batteryLockTimeout = 300;
      # Lock whenever the system suspends for any other reason (via logind
      # PrepareForSleep), replacing hypridle's before_sleep_cmd.
      lockBeforeSuspend = true;
    }
    // lib.optionalAttrs suspendEnabled {
      acSuspendTimeout = 1800;
      batterySuspendTimeout = 1800;
    };
in
  lib-mine.mkFeature "features.linux-desktop.lockscreen" {
    # The idle settings live in the (hot-reloaded) dms settings.json, for which
    # no home-manager options exist, so the relevant keys are merged in on
    # activation.
    home.activation.configureDmsLockscreen = lib.hm.dag.entryAfter ["writeBoundary"] ''
      settingsFile="${config.xdg.configHome}/DankMaterialShell/settings.json"
      mkdir -p "$(dirname "$settingsFile")"
      if [[ -s "$settingsFile" ]]; then
        ${lib.getExe pkgs.jq} --argjson new '${builtins.toJSON dmsIdleSettings}' '. * $new' \
          "$settingsFile" > "$settingsFile.lockscreen"
        mv "$settingsFile.lockscreen" "$settingsFile"
      else
        echo '${builtins.toJSON dmsIdleSettings}' > "$settingsFile"
      fi
    '';
  }
