{
  lib-mine,
  origin,
  pkgs,
  ...
}: let
  pkgs-unstable = origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
  lib-mine.mkFeature "features.linux-desktop.shell" {
    imports = [
      origin.inputs.noctalia.homeModules.default
    ];

    config = {
      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
      };

      home.packages = [
        pkgs-unstable.quickshell
      ];
    };
  }
