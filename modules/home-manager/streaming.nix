{lib-mine, ...}:
lib-mine.mkFeature "features.streaming" {
  programs.obs-studio = {
    enable = true;
  };
}
