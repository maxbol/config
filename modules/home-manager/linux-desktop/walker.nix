{
  pkgs,
  lib,
  lib-mine,
  origin,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.walker" {
  imports = [
    origin.inputs.walker.homeManagerModules.default
  ];

  config = {
    programs.walker = {
      enable = true;
      runAsService = true;
    };
  };
}
