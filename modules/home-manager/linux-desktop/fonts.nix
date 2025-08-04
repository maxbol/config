{
  lib-mine,
  pkgs,
  vendor,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.fonts" {
  fonts = {
    fontconfig.enable = true;
  };

  home.packages = [
    vendor.aporetic-kitty.default
    pkgs.iosevka
    pkgs.font-manager
  ];
}
