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
    pkgs.roboto-flex
    pkgs.roboto-slab
    pkgs.iosevka
    pkgs.font-manager
    pkgs.cantarell-fonts
    pkgs.input-fonts
    pkgs.inter-nerdfont
    pkgs.dm-sans
  ];
}
