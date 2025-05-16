{
  pkgs,
  lib-mine,
  ...
}:
lib-mine.mkFeature "features.darwin-desktop.sketchybar" {
  # Sketchybar is configured by home-manager/chroma, so no settings should be set in the darwin module
  services.sketchybar.enable = true;
  environment.systemPackages = [
    pkgs.sketchybar
  ];
}
