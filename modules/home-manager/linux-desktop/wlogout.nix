{
  lib-mine,
  self,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.wlogout" {
  programs.wlogout.enable = true;
  home.packages = [self.wlogout-launcher-hyprdots];
  impure-config-management.config."wlogout" = "config/wlogout";
}
