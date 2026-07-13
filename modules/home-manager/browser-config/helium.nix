{
  lib-mine,
  vendor,
  ...
}:
lib-mine.mkFeature "features.browser-config.helium" {
  home.packages = [
    vendor.helium.default
  ];
}
