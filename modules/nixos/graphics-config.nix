{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.graphics-config" {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

  environment.systemPackages = with pkgs; [mesa-demos glxinfo nvtopPackages.amd];
}
