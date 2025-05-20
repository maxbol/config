{
  config,
  pkgs,
  lib-mine,
  lib,
  self,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.rofi" {
  options = with lib; {
    activeWallpaperDir = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.xdg.stateHome}/nailgun/active-wallpaper";
    };
  };

  config = {
    programs.rofi = let
      kitty = config.programs.kitty.package;
    in {
      enable = true;
      package = pkgs.rofi-wayland;
      terminal = "${kitty}/bin/kitty";
      font = "Iosevka Nerd Font 14";
      # font = "JetBrainsMono Nerd Font 10";
      # FIXME: by default location, xoffset, yoffset are set; we probably don't want these set here
      imports = ["${config.xdg.configHome}/rofi/config.style.rasi"];
    };

    impure-config-management.config = lib.genAttrs ["rofi/clipboard.rasi" "rofi/quickapps.rasi" "rofi/themeselect.rasi" "rofi/styles"] (i: "config/${i}");

    home.activation.linkRofiDefaultStyle = lib.hm.dag.entryAfter ["write-boundary"] ''
      if ! [ -e "${config.xdg.configHome}/rofi/config.style.rasi" ]; then
        ln -s "${config.xdg.configHome}/rofi/styles/style_1.rasi" "${config.xdg.configHome}/rofi/config.style.rasi"
      fi
    '';

    home.packages = [
      self.rofi-launchers-hyprdots
      self.nailgun
      pkgs.iosevka
    ];

    theme-config.extraActivationCommands = theme: ''
      ${lib.getExe self.nailgun} thumbnails-for-theme "${config.theme-config.themeDirectory}/active/swim/wallpapers" >/dev/null &
    '';

    programs.swim.wallpaperActivationCommands = ''
      ${lib.getExe self.nailgun} activate-wallpaper "$WALLPAPER" >/dev/null &
    '';
  };
}
