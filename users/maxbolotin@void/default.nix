{...}: rec {
  home.stateVersion = "24.05";
  home.username = "maxbolotin";
  home.homeDirectory = "/Users/maxbolotin/";

  impure-config-management.symlink.enable = true;
  impure-config-management.symlink.base = "${home.homeDirectory}/dotfiles";

  features.browser-config.enable = true;
  features.darwin-desktop.enable = true;
  features.terminal-services.enable = true;
  features.nix-services.enable = true;
  features.tmux-config.enable = true;
  features.git-config.enable = true;
  features.secrets-management.enable = true;

  programs.git = {
    userName = "Max Bolotin";
    userEmail = "maks.bolotin@gmail.com";
  };
}
