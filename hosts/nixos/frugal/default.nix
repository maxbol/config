{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "frugal";

  users.users.max = {
    isNormalUser = true;
    description = "Max Bolotin";
    extraGroups = ["networkmanager" "wheel" "docker" "plugdev"];
    packages = [];
    shell = pkgs.zsh;
  };

  features.application-config.enable = true;
  features.core-services.enable = true;
  features.custom-udev-rules.enable = true;
  features.desktop-config.enable = true;
  features.localisation.enable = true;
  features.secrets-management.enable = true;
  features.system-start = {
    enable = true;
    defaultUser = "max";
  };
  features.vpn-config.enable = true;
}
