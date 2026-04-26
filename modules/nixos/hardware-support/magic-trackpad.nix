{lib-mine, ...}:
lib-mine.mkFeature "hardware-support.magic-trackpad" {
  boot.kernelModules = ["hid-apple"];
  boot.kernelParams = [
    "hid-apple.fnmode=2"
    "hid-apple.iso_layout=1"
    "hid-apple.swap_opt_cmd=0"
  ];
}
