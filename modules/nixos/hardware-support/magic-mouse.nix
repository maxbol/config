{lib-mine, ...}:
lib-mine.mkFeature "features.hardware-support.magic-mouse" {
  boot.kernelModules = ["hid_magicmouse"];
  boot.kernelParams = [
    "hid-magicmouse.scroll_acceleration=1"
    "hid-magicmouse.scroll_speed=55"
  ];
}
