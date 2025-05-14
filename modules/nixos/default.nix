{...}: {
  imports = [
    ./application-config
    ./core-services.nix
    ./custom-udev-rules
    ./desktop-config
    ./secrets-management.nix
    ./system-start.nix
    ./vpn-config
  ];
}
