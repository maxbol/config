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
  }
