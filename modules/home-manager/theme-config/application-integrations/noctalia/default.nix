{
  pkgs,
  config,
  lib,
  lib-mine,
  ...
}:
with lib; let
  inherit (lib-mine.types) colorType;
  cfg = config.theme-config;
in {
  options = {
    theme-config.noctalia = {
      enable = mkOption {
        type = types.bool;
        default = config.programs.noctalia-shell.enable;
        example = false;
        description = ''
          Whether to enable Noctalia themeing as part of Chroma.
        '';
      };
    };
  };

  config = {
    theme-config.programs.noctalia = {
      themeOptions = {
        predefinedColorscheme = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Use one of the standard colorschemes shipped with noctalia instead of generating one.
          '';
        };

        predefinedColorschemeLuminance = mkOption {
          type = types.enum ["dark" "light"];
          default = "dark";
          description = ''
            What luminance to use with the predefined colorscheme if that is used.
          '';
        };

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
      }: let
        colors = opts.palette.generateDynamic {
          template = ./colors.json.dyn;
          paletteOverrides = config.colorOverrides;
        };

        colorsJson = builtins.fromJSON (builtins.readFile colors);

        colorscheme = {
          dark = colorsJson;
          light = colorsJson;
        };
      in (
        mkMerge
        [
          (mkIf (config.predefinedColorscheme
            == null) {
            file."colors.json" = {
              required = true;
              source = colors;
            };

            file."colorscheme.json" = {
              required = true;
              text = builtins.toJSON colorscheme;
            };
          })
        ]
      );

      activationCommand = {
        name,
        opts,
        ...
      }:
        if opts.predefinedColorscheme != null
        then ''
          noctalia-shell ipc call colorScheme set ${opts.predefinedColorscheme}
          noctalia-shell ipc call darkMode ${
            if opts.predefinedColorschemeLuminance == "dark"
            then "setDark"
            else "setLight"
          }
        ''
        else ''
          noctalia-shell ipc call colorScheme set ${name}
        '';
    };
  };

  imports = [
    (
      mkIf (cfg.enable && cfg.noctalia.enable)
      {
        home.activation.copyNoctaliaColorschemes = lib.hm.dag.entryAfter ["linkChromaDefault"] ''
          for theme in ${config.theme-config.themeDirectory}/themes/*; do
            themeName=$(basename $theme)
            source="$theme/noctalia/colorscheme.json"
            targetDir="$HOME/.config/noctalia/colorschemes/$themeName"
            [[ -d "$targetDir" ]] && rm -Rf $targetDir
            mkdir -p $targetDir
            target="''${targetDir}/''${themeName}.json"
            [[ -f "$source" ]] && cp -RL $source $target
          done
        '';
      }
    )
  ];
}
