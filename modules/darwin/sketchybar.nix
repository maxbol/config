{pkgs, ...}: {
  # Sketchybar is configured by home-manager/chroma, so no settings should be set in the darwin module
  environment.systemPackages = [
    pkgs.sketchybar
  ];
  services.sketchybar.enable = true;
}
