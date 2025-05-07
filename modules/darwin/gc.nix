{...}: {
  nix.gc = {
    automatic = true;
    interval.Hour = 0;
    options = "--delete-older-than 1d";
  };
}
