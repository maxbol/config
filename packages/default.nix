packageArgs @ {pkgs, ...}: {
  aerospace-swipe = pkgs.callPackage ./aerospace-swipe packageArgs;
  chromactl = pkgs.callPackage ./chromactl packageArgs;
  clockify-cli = pkgs.callPackage ./clockify-cli packageArgs;
  clockify-tmux = pkgs.callPackage ./clockify-tmux packageArgs;
  dynachrome = pkgs.callPackage ./dynachrome packageArgs;
  gtkrc-reload = pkgs.callPackage ./gtkrc-reload packageArgs;
  hyprdots-kvantum = pkgs.callPackage ./hyprdots-kvantum packageArgs;
  hyprdots-qt5ct = pkgs.callPackage ./hyprdots-qt5ct packageArgs;
  libadwaita-without-adwaita = pkgs.callPackage ./libadwaita-without-adwaita packageArgs;
  nancy = pkgs.callPackage ./nancy packageArgs;
  rofi-launchers-hyprdots-swwwallselect-patch = pkgs.callPackage ./rofi-launchers-hyprdots-swwwallselect-patch packageArgs;
  runcached = pkgs.callPackage ./runcached packageArgs;
  synp = pkgs.callPackage ./synp packageArgs;
  zathura-darwin = pkgs.callPackage ./zathura-darwin packageArgs;
  zathura-darwin-app = pkgs.callPackage ./zathura-darwin-app packageArgs;
}
