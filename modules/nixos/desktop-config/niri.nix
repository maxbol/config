{
  lib-mine,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.desktop-config.niri" {
  imports = [
    origin.inputs.niri.nixosModules.niri
  ];
  config = {
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-unstable;

    # niri-flake.cache.enable = false;

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.gnome-keyring pkgs.xdg-desktop-portal-wlr]; # Gnome portal already added by `programs.niri`
    };
  };
}
