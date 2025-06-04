{
  config,
  lib,
  lib-mine,
  pkgs,
  ...
}:
with lib; let
  cfg = config.theme-config;

  inherit (lib-mine.types) colorType;
in {
  options = {
    theme-config.wlogout.enable = mkOption {
      type = types.bool;
      default = config.programs.wlogout.enable;
      example = false;
      description = ''
        Whether to enable wlogout themeing.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.wlogout.enable) || config.programs.wlogout.enable;
        message = "Themeing integration for wlogout requires base wlogout module";
      }
    ];

    theme-config.programs.wlogout = {
      themeOptions = {
        colorOverrides = mkOption {
          type = with types; attrsOf colorType;
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
        file."theme.css" = {
          required = true;
          source = mkDefault (opts.palette.generateDynamic {
            template = ./wlogout.css.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };
      };
    };
  };
}
