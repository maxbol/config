packageArgs @ {pkgs, ...}: let
  addPackage = pkg: pkgs.callPackage pkg packageArgs;
in {
  aerospace-swipe = addPackage ./aerospace-swipe;
  chromactl = addPackage ./chromactl;
  clockify-cli = addPackage ./clockify-cli;
  clockify-tmux = addPackage ./clockify-tmux;
  dynachrome = addPackage ./dynachrome;
  gtkrc-reload = addPackage ./gtkrc-reload;
  hyprdots-kvantum = addPackage ./hyprdots-kvantum;
  hyprdots-qt5ct = addPackage ./hyprdots-qt5ct;
  hyprpanel-themes = addPackage ./hyprpanel-themes;
  hyprscroller = addPackage ./hyprscroller;
  libadwaita-without-adwaita = addPackage ./libadwaita-without-adwaita;
  misc-scripts-hyprdots = addPackage ./misc-scripts-hyprdots;
  nailgun = addPackage ./nailgun;
  nancy = addPackage ./nancy;
  openssl_1_0 = addPackage ./openssl_1_0;
  rofi-launchers-hyprdots = addPackage ./rofi-launchers-hyprdots;
  runcached = addPackage ./runcached;
  sddm-theme-corners = addPackage ./sddm-theme-cornersnix packageArgs;
  swimctl = addPackage ./swimctl;
  synp = addPackage ./synp;
  systemctl-toggle = addPackage ./systemctl-toggle;
  waybar-confgen-hyprdots = addPackage ./waybar-confgen-hyprdots;
  wlogout-launcher-hyprdots = addPackage ./wlogout-launcher-hyprdots;
  zathura-darwin = addPackage ./zathura-darwin;
  zathura-darwin-app = addPackage ./zathura-darwin-app;
}
