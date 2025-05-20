{lib-mine, ...}:
lib-mine.mkFeature "features.desktop-config.ui-toolkits" {
  environment.variables = {
    "QT_STYLE_OVERRIDE" = "kvantum";
  };
}
