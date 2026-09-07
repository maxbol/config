{...}: {
  imports = [
    ./application-config
    ./core-services.nix
    ./desktop-config
    ./graphics-config.nix
    ./hardware-support
    ./kde-connect-firewall.nix
    ./localsend.nix
    ./localisation.nix
    ./nix-registry.nix
    ./nix-store-tooling.nix
    ./secrets-management.nix
    ./server
    ./system-start.nix
    ./vpn-config
  ];
}
