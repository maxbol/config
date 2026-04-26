{origin, ...}: {
  imports = [
    origin.inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  boot.loader.grub.enable = true;

  services.openssh.enable = true;

  users.users.max = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialHashedPassword = "$y$j9T$2DyEjQxPoIjTkt8zCoWl.0$3mHxH.fqkCgu53xa0vannyu4Cue3Q7xL4CrUhMxREKC";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  system.stateVersion = "25.05";
}
