{
  lib,
  lib-mine,
  pkgs,
  specialArgs,
  ...
}:
lib-mine.mkFeature "features.linux-theme-defaults" {
  systemd.user.startServices = "sd-switch";
  theme-config = lib.mkMerge [
    {
      enable = true;
      initialTheme = "Tsoding-Mode";
      themes = (import ./themes) {inherit pkgs specialArgs;};

      dynawall.enable = true;
      desktop.enable = true;
      gtk = {
        enable = true;
        gtk4.libadwaitaSupport = "patch-binary";
      };
      qt.enable = true;
    }
  ];
}
