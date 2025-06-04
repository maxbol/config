{
  lib-mine,
  lib,
  config,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.swim" {
  # services.swww.enable = true;
  programs.swww = {
    enable = true;
    systemd = {
      enable = true;
      installTarget = ["hyprland-session.target" "niri.service"];
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
