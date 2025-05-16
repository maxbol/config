{
  lib-mine,
  lib,
  ...
}:
lib-mine.mkFeature "features.graphics-config" ({config, ...}: let
  cfg = config.features.graphics-config;
in {
  options = {
    nvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
  config = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = lib.mkIf (cfg.nvidia) {
      modesetting.enable = true;
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
      powerManagement.enable = true;
      # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #   version = "555.42.02";
      #   sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
      #   sha256_aarch64 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #   openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #   settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #   persistencedSha256 = lib.fakeSha256;
      # };
    };
  };
})
