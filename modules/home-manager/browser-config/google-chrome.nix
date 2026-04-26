{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.browser-config.google-chrome" {
  home.packages = with pkgs; [
    google-chrome
  ];
}
