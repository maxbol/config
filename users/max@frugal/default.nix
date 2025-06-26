{
  pkgs,
  config,
  ...
}: rec {
  home.stateVersion = "24.11";
  home.username = "max";
  home.homeDirectory = "/home/max/";

  impure-config-management.symlink.enable = true;
  impure-config-management.symlink.base = "${home.homeDirectory}/src/config";

  features.browser-config.enable = true;
  # features.secrets-management.enable = true;
  features.application-support.enable = true;
  features.default-development-environment.enable = true;
  features.office-suite.enable = true;
  features.streaming.enable = true;
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

  home.sessionVariables = {
    NH_HOME_FLAKE = "${config.home.homeDirectory}/src/config";
  };

  xdg.mimeApps.defaultApplications = {
    "model/gltf-binary" = ["f3d.desktop"];
    "model/gltf+json" = ["f3d.desktop"];
  };

  home.packages = with pkgs; [
    nautilus
    slack
    discord
    spotify
    f3d
    zenity
    file
  ];
}
