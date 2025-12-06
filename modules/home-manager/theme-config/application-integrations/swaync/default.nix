{
  config,
  lib,
  lib-mine,
  ...
}:
with lib; let
  cfg = config.theme-config;
  inherit (lib-mine.types) colorType;
in {
  options = {
    theme-config.swaync.enable = mkOption {
      type = types.bool;
      default = config.services.swaync.enable;
      # default = false;
      example = false;
      description = ''
        Whether to enable swaync themeing as part of the theme integration.
      '';
    };
  };

  config = {
    # assertions = [
    #   {
    #     assertion = !cfg.enable || config.services.swaync.enable;
    #     message = "Swaync theme integration only works when the swaync home-manager module is enabled.";
    #   }
    # ];

    theme-config.programs.swaync = {
      themeOptions = {
        colorOverrides = lib.mkOption {
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
        file."style.css" = {
          required = true;
          source = opts.palette.generateDynamic {
            template = ./style.css.dyn;
            paletteOverrides = config.colorOverrides;
          };
        };
      };

      reloadCommand = "systemctl restart --user swaync";
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.swaync.enable) {
      xdg.configFile."swaync/style.css" = {
        source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeDirectory}/active/swaync/style.css";
      };
    })
  ];
}
