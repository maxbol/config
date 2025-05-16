{
  lib,
  lib-mine,
  pkgs,
  specialArgs,
  ...
}:
lib-mine.mkFeature "features.theme-defaults" {
  systemd.user.startServices = "sd-switch";
  theme-config = lib.mkMerge [
    {
      enable = true;
      initialTheme = "Tsoding-Mode";
      themes = (import ./themes) {inherit pkgs specialArgs;};
    }
    (
      lib.mkIf
      (pkgs.stdenv.hostPlatform.isDarwin)
      {
        desktop.enable = true;
      }
    )
  ];
}
