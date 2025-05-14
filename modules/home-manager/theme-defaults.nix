{
  lib,
  lib-mine,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.theme-defaults" {
  theme-config = lib.mkMerge [
    {
      enable = true;
      initialTheme = "Tsoding-Mode";
      themes = origin.outputs.themes.${pkgs.system};
    }
    # (lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    #   gtk = {
    #     enable = true;
    #     gtk4.libadwaitaSupport = "patch-binary";
    #   };
    #   qt.enable = true;
    # })
  ];
}
