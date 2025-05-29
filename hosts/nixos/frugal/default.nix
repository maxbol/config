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

  environment.systemPackages = with pkgs; [vim];

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = ["max"];
  };

  # systemd.tmpfiles.rules = [
  #   "f /var/lib/systemd/linger/max"
  # ];

  features.application-config.enable = true;
  features.core-services.enable = true;
  features.desktop-config.enable = true;
  features.hardware-support.enable = true;
  features.graphics-config.enable = true;
  features.localisation.enable = true;
  features.nix-registry.enable = true;
  features.secrets-management.enable = true;
  features.system-start = {
    enable = true;
    defaultUser = "max";
  };
  # features.vpn-config.enable = true;

  system.stateVersion = "24.11";
}
