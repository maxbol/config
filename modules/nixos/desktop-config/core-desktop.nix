{
  lib-mine,
  pkgs,
  ...
}: let
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

      # Better cursor scaling in java apps
      # XCURSOR_SIZE = 28;
    };

    programs.dconf.enable = true;

    # Provides gnome-disk-image-mounter, which is what Nautilus actually
    # invokes to loop-mount ISOs via udisks2.
    environment.systemPackages = [pkgs.gnome-disk-utility];

    # # Raise the default 8M memlock limit (inherited by user@.service and thus
    # # user units) so nautilus-keepwarm can pin nautilus + its libs in RAM.
    # systemd.extraConfig = "DefaultLimitMEMLOCK=512M";

    # Required to allow swaylock/hyprlock to unlock.
    security.pam.services.swaylock = {};
    security.pam.services.hyprlock = {};

    # Required by end-4's AGS config. I'm not sure what for.
    users.users.max.extraGroups = ["video" "input"];

    # Required for uniform cursor scaling in Jetbrains apps
    # services.xserver.dpi = 122;
  }
