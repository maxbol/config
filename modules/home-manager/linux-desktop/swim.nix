{
  lib-mine,
  lib,
  config,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.swim" {
  programs.swww = {
    enable = true;
    systemd = {
      enable = true;
      installTarget = "hyprland-session.target";
    };
  };

  programs.swim = {
    enable = true;
    chromaIntegration = {
      enable = true;
    };
    wallpaperDirectory = lib.mkDefault "${config.home.homeDirectory}/wallpapers";
    # extraSwwwArgs = lib.mkIf config.features.linux-desktop.hyprland.enable [''--transition-pos'' ''"$( hyprctl cursorpos )"''];
  };
}
