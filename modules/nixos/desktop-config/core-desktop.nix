{
  origin,
  lib-mine,
  pkgs,
  ...
}: let
  nerdfonts = origin.inputs.nixpkgs-legacy.legacyPackages.${pkgs.system}.nerdfonts;
in
  lib-mine.mkFeature "features.desktop-config.core-desktop" {
    # The name is a remnant of former times. This just enables graphical sessions.
    services.xserver.enable = true;
    # Needed so localectl can work
    services.xserver.exportConfiguration = true;

    environment.sessionVariables = {
      # Enable Wayland support for Electron apps.
      NIXOS_OZONE_WL = "1";

      # Nicer fonts in Java apps
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
    };

    environment.systemPackages = [
      nerdfonts
    ];

    programs.dconf.enable = true;

    # Required to allow swaylock/hyprlock to unlock.
    security.pam.services.swaylock = {};
    security.pam.services.hyprlock = {};

    # Required by end-4's AGS config. I'm not sure what for.
    users.users.max.extraGroups = ["video" "input"];
  }
