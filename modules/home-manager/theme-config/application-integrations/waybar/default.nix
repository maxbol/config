{
  pkgs,
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
    theme-config.waybar.enable = mkOption {
      type = types.bool;
      default = config.programs.waybar.enable;
      example = false;
      description = ''
        Whether to enable waybar theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.waybar.enable) || config.programs.waybar.enable;
        message = "Chroma integration for Waybar requires base waybar module.";
      }
    ];

    theme-config.programs.waybar = {
      reloadCommand = ''systemctl --user restart waybar'';

      themeOptions = {
        opacity = mkOption {
          type = types.float;
          default = 0.8;
          description = ''
            The opacity of the bar background color.
          '';
        };

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
            template = pkgs.runCommand "waybar.css.dyn" {} ''
              ${pkgs.gnused}/bin/sed 's/%OPACITY%/${builtins.toString config.opacity}/g' ${./waybar.css.dyn} > $out
            '';
            paletteOverrides = config.colorOverrides;
          });
        };
      };
    };

    programs.waybar.style = mkIf (cfg.enable && cfg.waybar.enable) ''
      @import "${config.theme-config.themeDirectory}/active/waybar/theme.css";
    '';
  };
}
