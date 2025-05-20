{pkgs, ...}: rec {
  home.stateVersion = "24.11";
  home.username = "max";
  home.homeDirectory = "/home/max/";

  impure-config-management.symlink.enable = true;
  impure-config-management.symlink.base = "${home.homeDirectory}/src/config";

  features.browser-config.enable = true;
  # features.secrets-management.enable = true;
  features.application-support.enable = true;
  features.application-support.obsidian.enable = false;
  features.default-development-environment.enable = true;
  features.git-config.enable = true;
  features.linux-desktop.enable = true;
  features.nix-services.enable = true;
  features.terminal-services.enable = true;
  features.terminal-services.terminal-config.enable = true;
  features.linux-theme-defaults.enable = true;
  features.tmux-config.enable = true;

  identity = {
    userImage = ./image.jpg;
  };

  programs.git = {
    userName = "Max Bolotin";
    userEmail = "maks.bolotin@gmail.com";
  };

  home.packages = with pkgs; [
    xfce.thunar
    dolphin
    nautilus
  ];
}
