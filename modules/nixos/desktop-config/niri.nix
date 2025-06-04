{
  lib-mine,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.desktop-config.niri" {
  imports = [
    origin.inputs.niri.nixosModules.niri
  ];
  config = {
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-unstable;
  };
}
