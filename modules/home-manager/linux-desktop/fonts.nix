{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.fonts" {
  fonts = {
    fontconfig.enable = true;
  };

  home.packages = [
    pkgs.iosevka
    pkgs.font-manager
  ];
}
