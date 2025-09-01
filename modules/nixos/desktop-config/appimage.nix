{lib-mine, ...}:
lib-mine.mkFeature "features.desktop-config.appimage" {
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
}
