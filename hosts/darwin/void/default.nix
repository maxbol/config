{pkgs, ...}: {
  imports = [
    ../../../modules/darwin/aerospace.nix
    ../../../modules/darwin/gc.nix
    ../../../modules/darwin/jankyborders.nix
    ../../../modules/darwin/registry.nix
    ../../../modules/darwin/sketchybar.nix
    ./nix-settings.nix
    ./system.nix
  ];

  environment.systemPackages = [
    pkgs.nodejs
  ];
}
