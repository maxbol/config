{
  lib-mine,
  origin,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.launcher" {
  imports = [
    origin.inputs.vicinae.homeManagerModules.default
  ];

  config = {
    # Force vicinae to depend on all XCURSOR_* vars set by niri
    systemd.user.services.vicinae-env-import = {
      Unit = {
        Before = ["vicinae.service"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "systemctl --user import-environment XCURSOR_SIZE XCURSOR_THEME XCURSOR_PATH";
      };

      Install.WantedBy = ["vicinae.service"];
    };

    services.vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
        target = "niri.service";
        environment = {
          USE_LAYER_SHELL = 1;
        };
      };
    };
  };
}
