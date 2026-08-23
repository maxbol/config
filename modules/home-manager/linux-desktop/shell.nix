{
  lib-mine,
  origin,
  vendor,
  ...
}: let
  # pkgs-unstable = origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
  lib-mine.mkFeature "features.linux-desktop.shell" {
    imports = [
      origin.inputs.noctalia.homeModules.default
      origin.inputs.dms.homeModules.dank-material-shell
    ];

    config = {
      # programs.noctalia-shell = {
      #   enable = true;
      #   systemd.enable = true;
      # };

      programs.dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;
        systemd.enable = true;
        # Keeps matugen off the PATH so dms doesn't try to generate GTK/Qt
        # system themes on every theme switch (Chroma owns those files as
        # read-only store links, so generation would fail with an OSD error).
        enableDynamicTheming = false;
      };

      home.packages = [
        vendor.dankcalendar.default
      ];

      # dankcalendar has no module of its own to hang this off of.
      theme-config.dankcal.enable = true;

      # home.packages = [
      #   pkgs-unstable.quickshell
      # ];
    };
  }
