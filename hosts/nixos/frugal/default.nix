{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  config.hardware.bluetooth.enable = true;

  features.application-config.enable = true;
  features.core-services.enable = true;
  features.custom-udev-rules.enable = true;
  features.desktop-config.enable = true;
  features.secrets-management.enable = true;
  features.system-start.enable = true;
  features.vpn-config.enable = true;
}
