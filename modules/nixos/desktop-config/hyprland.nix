{
  lib-mine,
  pkgs,
  origin,
  vendor,
  ...
}:
lib-mine.mkFeature "features.desktop-config.hyprland" {
  imports = [
    origin.inputs.hyprland.nixosModules.default
  ];

  maxdots.feature.desktop.enable = true;

  programs.hyprland = {
    enable = true;
    package = vendor.hyprland.default;
    portalPackage = vendor.hyprland.xdg-desktop-portal-hyprland;
  };
  # xdg-desktop-portal-hyprland is implicitly included by the Hyprland module
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  programs.dconf.enable = true;

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    nerdfonts
  ];

  # Required to allow swaylock/hyprlock to unlock.
  security.pam.services.swaylock = {};
  security.pam.services.hyprlock = {};

  # Required by end-4's AGS config. I'm not sure what for.
  users.users.max.extraGroups = ["video" "input"];
}
