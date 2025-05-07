{pkgs, ...}: {
  home.stateVersion = "24.05";
  home.username = "maxbolotin";
  home.homeDirectory = "/Users/maxbolotin/";

  home.packages = [
    pkgs.nodejs
    pkgs.fastfetch
  ];
}
