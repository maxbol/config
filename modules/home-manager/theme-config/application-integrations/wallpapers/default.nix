{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.theme-config;
in {
  options = {
    theme-config.wallpapers.enable =
      mkEnableOption "the wallpapers a theme ships with"
      // {
        default = true;
        example = false;
      };
  };

  config = {
    # Exposes each theme's wallpapers at a stable path
    # ("<themeDirectory>/active/wallpapers"), which is all this integration
    # does: which of them is on screen is up to whatever renders the
    # wallpaper. Nothing is activated here.
    theme-config.programs.wallpapers = {
      themeOptions = {
        wallpaperDirectory = mkOption {
          type = with types; nullOr (oneOf [str path]);
          default = null;
          example = literalExpression "./wallpapers";
          description = ''
            Where this theme's wallpapers live. A path is copied into the Nix
            store, a string is used as-is.
          '';
        };
      };

      themeConfig = {config, ...}:
        mkIf (config.wallpaperDirectory != null) {
          # Named so the images do not land at "wallpapers/wallpapers": the
          # program directory is already called wallpapers.
          file."images".source = config.wallpaperDirectory;
        };
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.wallpapers.enable) {
      assertions = [
        {
          assertion = all (theme: theme.wallpapers.wallpaperDirectory != null) (attrValues cfg.finalThemes);
          message = "Every theme needs wallpapers.wallpaperDirectory set while the Chroma wallpapers integration is enabled.";
        }
      ];
    })
  ];
}
