{
  lib-mine,
  pkgs,
  origin,
  ...
}:
lib-mine.mkFeature "features.desktop-config.hyprland" {
  config = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
