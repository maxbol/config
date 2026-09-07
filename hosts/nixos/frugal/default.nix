{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "frugal";

  users.users.max = {
    isNormalUser = true;
    description = "Max Bolotin";
    extraGroups = ["networkmanager" "wheel" "docker" "plugdev" "input" "greeter"];
    packages = [];
    shell = pkgs.zsh;
  };

  # The internal panel is the only display with Panel Self Refresh active
  # ("eDP-2: PSR support 1, sink PSR ver 1"), and it intermittently keeps
  # showing its last self-refreshed frame after a resume: the compositor
  # carries on rendering, but nothing new reaches the panel until something
  # forces a modeset. A resume that froze it logged a WARN inside
  # dmub_psr_enable. 0x10 is DC_DISABLE_PSR, which trades a little idle power
  # on battery for a panel that keeps updating.
  boot.kernelParams = ["amdgpu.dcdebugmask=0x10"];

  environment.systemPackages = with pkgs; [vim openssl lm_sensors];

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
  features.desktop-config.hyprland.enable = false;
  features.hardware-support.enable = true;
  features.graphics-config.enable = true;
  features.kde-connect-firewall.enable = true;
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
