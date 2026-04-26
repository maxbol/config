{lib-mine, ...}:
lib-mine.mkFeature "features.desktop-config.flatpak" {
  services.flatpak.enable = true;
}
