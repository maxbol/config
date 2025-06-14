{
  lib-mine,
  self,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.fonts" {
  fonts = {
    fontconfig.enable = true;
  };

  home.packages = [
    self.aporetic-kitty
    pkgs.iosevka
    pkgs.font-manager
  ];
}
