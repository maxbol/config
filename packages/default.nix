packageArgs @ {pkgs, ...}: {
  clockify-cli = pkgs.callPackage ./clockify-cli packageArgs;
  clockify-tmux = pkgs.callPackage ./clockify-tmux packageArgs;
  dynachrome = pkgs.callPackage ./dynachrome packageArgs;
  hyprdots-kvantum = pkgs.callPackage ./hyprdots-kvantum packageArgs;
  hyprdots-qt5ct = pkgs.callPackage ./hyprdots-qt5ct packageArgs;
  nancy = pkgs.callPackage ./nancy packageArgs;
  rofi-launchers-hyprdots-swwwallselect-patch = pkgs.callPackage ./rofi-launchers-hyprdots-swwwallselect-patch packageArgs;
  runcached = pkgs.callPackage ./runcached packageArgs;
  synp = pkgs.callPackage ./synp packageArgs;
  zathura-darwin = pkgs.callPackage ./zathura-darwin packageArgs;
  zathura-darwin-app = pkgs.callPackage ./zathura-darwin-app packageArgs;
}
