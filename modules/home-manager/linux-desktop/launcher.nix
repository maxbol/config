{
  lib-mine,
  origin,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.launcher" {
  imports = [
    origin.inputs.vicinae.homeManagerModules.default
  ];

  config = {
    services.vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
        environment = {
          USE_LAYER_SHELL = 1;
        };
      };
    };
  };
}
