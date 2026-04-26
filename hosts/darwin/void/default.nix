{pkgs, ...}: {
  imports = [
    ./nix-settings.nix
    ./system.nix
  ];

  features.gc.enable = true;
  features.nix-registry.enable = true;
  features.darwin-desktop.enable = true;

  environment.systemPackages = [
    pkgs.nodejs
  ];
}
