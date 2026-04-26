{
  config,
  lib-mine,
  pkgs,
  specialArgs,
  ...
}:
lib-mine.mkFeature "features.linux-theme-defaults" {
  systemd.user.startServices = "sd-switch";

  theme-config = {
    enable = true;
    initialTheme = "Tsoding-Mode";
    themes = (import ./themes) {inherit pkgs specialArgs;};

    systemdTarget = ["hyprland-session.target" "niri.service"];

    dynawall.enable = true;
    desktop.enable = true;
    gtk = {
      enable = true;
      # gtk4.libadwaitaSupport = "patch-binary";
      gtk4.libadwaitaSupport = "import";
    };
    qt.enable = true;
  };

  systemd.user.services.chroma-launch = {
    Unit = {
      Description = "Set up theming scripts";
      After = ["graphical-session-pre.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${config.theme-config.themeDirectory}/active/activate";
      Restart = "no";
    };

    Install.WantedBy = ["hyprland-session.target" "niri.service"];
  };
}
