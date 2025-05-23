{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.gaming" {
  home.packages = with pkgs; [lutris];
}
