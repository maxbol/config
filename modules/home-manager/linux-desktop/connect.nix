{lib-mine, ...}:
lib-mine.mkFeature "features.linux-desktop.connect" {
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}
