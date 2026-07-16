{
  pkgs,
  lib-mine,
  origin,
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
      };

      # home.packages = [
      #   pkgs-unstable.quickshell
      # ];
    };
  }
