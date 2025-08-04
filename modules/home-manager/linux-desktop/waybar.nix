{
  config,
  lib-mine,
  lib,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.waybar" {
  home.packages = [pkgs.pavucontrol];

  impure-config-management.config = lib.genAttrs [
    # "waybar/config.ctl"
    "waybar/modules"
    "waybar/config"
    "waybar/nix.svg"
  ] (n: "config/${n}");

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "niri.service";
  };
}
