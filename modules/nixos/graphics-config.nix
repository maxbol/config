{lib-mine, ...}:
lib-mine.mkFeature "features.graphics-config" {
  config = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
