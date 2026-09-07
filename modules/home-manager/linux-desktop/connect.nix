{lib-mine, ...}:
lib-mine.mkFeature "features.linux-desktop.connect" {
  services.kde-connect = {
    enable = true;
  };
}
