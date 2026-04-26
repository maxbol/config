{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.theme-config;

  tomlFormat = pkgs.formats.toml {};
in {
  options = {
    theme-config.starship.enable = mkEnableOption "Chroma integration for starship" // {default = config.programs.starship.enable;};
  };

  config = mkMerge [
    {
      theme-config.programs.starship = {
        themeOptions = {
          palette.file = mkOption {
            type = with types; either str path;
            example = literalExpression ''
              (pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "starship";
                  rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
                  hash = "sha256-soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
                }
                + /palettes/latte.toml
            '';
            description = "Path to the palette file";
          };

          palette.name = mkOption {
            type = types.str;
            example = "catppuccin_latte";
            description = "Name of the palette. Must be one of the palettes in the palette file.";
          };
        };

        themeConfig = {opts, ...}: {
          file."starship.toml".source = tomlFormat.generate "starship-chroma-config" (config.programs.starship.settings
            // {
              character = {
                success_symbol = "[❯](bold green)";
                error_symbol = "[❯](bold red)";
              };
            }
            // {
              palette = opts.starship.palette.name;
            }
            // builtins.fromTOML (builtins.readFile (opts.starship.palette.file)));
        };
      };
    }
    (mkIf (cfg.enable && cfg.starship.enable) {
      # IDEA: add functionality to Chroma to generate these symlinks from there?
      home.file.".config/starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeDirectory}/active/starship/starship.toml";
      };
    })
  ];
}
