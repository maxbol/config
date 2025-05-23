{...}: {
  imports = [
    ./application-config
    ./core-services.nix
    ./desktop-config
    ./graphics-config.nix
    ./hardware-support
    ./localisation.nix
    ./nix-registry.nix
    ./secrets-management.nix
    ./system-start.nix
    ./vpn-config
  ];
}
