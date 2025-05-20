{lib-mine, ...}:
lib-mine.mkFeature "features.linux-desktop.ui-toolkits" {
  home.sessionVariables = {
    "QT_STYLE_OVERRIDE" = "kvantum";
  };
}
