{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.graphics-config" {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [mesa-demos glxinfo vulkan-extension-layer];
}
