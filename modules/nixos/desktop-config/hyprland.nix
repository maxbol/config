{
  lib-mine,
  pkgs,
  origin,
  ...
}:
lib-mine.mkFeature "features.desktop-config.hyprland" {
  # imports = [
  #   origin.inputs.hyprland.nixosModules.default
  # ];

  config = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    # xdg-desktop-portal-hyprland is implicitly included by the Hyprland module
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
