{lib-mine, ...}:
lib-mine.mkFeature "features.office-suite" {
  programs.onlyoffice = {
    enable = true;
  };
}
