{origin, ...}: {
  system.configurationRevision = origin.rev or origin.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  services.nix-daemon.enable = true;
}
