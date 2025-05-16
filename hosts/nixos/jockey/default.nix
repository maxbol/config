# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Incluse results of the hardware scan
    ./hardware-configuration.nix
  ];

  # Manually turn of bluetooth - USB adapter
  config.hardware.bluetooth.enable = true;

  features.application-config.enable = true;
  features.core-services.enable = true;
  features.custom-udev-rules.enable = true;
  features.desktop-config.enable = true;
  features.localisation.enable = true;
  features.secrets-management.enable = true;
  features.system-start.enable = true;
  features.vpn-config.enable = true;

  config.networking.hostName = "jockey";

  config.users.groups.docker = {};
  config.users.groups.plugdev = {};

  config.users.users.max = {
    isNormalUser = true;
    description = "Max Bolotin";
    extraGroups = ["networkmanager" "wheel" "docker" "plugdev"];
    packages = [];
    shell = pkgs.zsh;
  };

  # Enable networking
  config.networking.networkmanager.enable = true;

  # No firwall for now, will switch when real install
  config.networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  config.system.stateVersion = lib.mkForce "23.11"; # Did you read the comment?
}
