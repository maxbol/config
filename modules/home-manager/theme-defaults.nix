{
  lib,
  lib-mine,
  pkgs,
  specialArgs,
  ...
}:
lib-mine.mkFeature "features.theme-defaults" {
  systemd.user.startServices = "sd-switch";
  theme-config = {
    enable = true;
    initialTheme = "Tsoding-Mode";
    themes = (import ./themes) {inherit pkgs specialArgs;};
  };
}
