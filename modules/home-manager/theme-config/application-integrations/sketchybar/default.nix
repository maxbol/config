{
  lib,
  pkgs,
  lib-mine,
  ...
}:
with lib; let
  inherit (lib-mine.types) colorType;
in {
  options = {
    theme-config.sketchybar.enable = mkOption {
      type = types.bool;
      # default = false;
      default = pkgs.stdenv.hostPlatform.isDarwin;
      example = false;
      description = ''
        Whether to enable Chroma theming for Sketchybar.
      '';
    };
  };

  config = {
    theme-config.programs.sketchybar = {
      themeOptions = {
        colorOverrides = mkOption {
          type = types.attrsOf colorType;
          default = {};
          description = ''
            Color overrides to apply to the palette-generated theme.
          '';
        };
      };

      themeConfig = {
        config,
        opts,
        ...
      }: {
        file."colors.sh" = {
          required = true;
          source = mkDefault (opts.palette.generateDynamic {
            template = ./colors.sh.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };
      };

      reloadCommand = "sh -c 'sketchybar --reload'";
    };
  };
}
