{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  features.application-config.enable = true;
  features.core-services.enable = true;
  features.custom-udev-rules.enable = true;
  features.desktop-config.enable = true;
  features.localisation.enable = true;
  features.secrets-management.enable = true;
  features.system-start.enable = true;
  features.vpn-config.enable = true;
}
