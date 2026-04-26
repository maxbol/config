{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "frugal";

  users.users.max = {
    isNormalUser = true;
    description = "Max Bolotin";
    extraGroups = ["networkmanager" "wheel" "docker" "plugdev" "input"];
    packages = [];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [vim openssl];

  environment.variables = {
    NH_OS_FLAKE = "/home/max/src/config";
  };

  nix.settings = {
    experimental-features = "nix-command flakes pipe-operators";
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
  features.localsend.enable = true;
  features.localisation.enable = true;
  features.nix-registry.enable = true;
  features.nix-store-tooling.enable = true;
  features.secrets-management.enable = true;
  features.server.enable = false;
  features.system-start = {
    enable = true;
    defaultUser = "max";
  };
  # features.vpn-config.enable = true;

  services.timesyncd.enable = true;
  systemd.watchdog.rebootTime = "45s";

  system.stateVersion = "24.11";
}
