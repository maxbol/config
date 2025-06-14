{
  pkgs,
  config,
  lib,
  origin,
  lib-mine,
  vendor,
  ...
}: let
  cfg = config.theme-config;
  inherit (lib-mine.types) colorType;
in
  with lib; {
    options = {
      theme-config.obsidian.enable = mkOption {
        type = types.bool;
        default = config.programs.obsidian.enable;
        example = false;
        description = ''
          Whether to enable Obsidian settings as part of Chroma.
        '';
      };
    };

    config = {
      theme-config.programs.obsidian = {
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
          file."obsidianChroma" = {
            source = let
              dynamicPalette =
                opts.palette.generateDynamic
                {
                  template = ./theme/theme.css.dyn;
                  paletteOverrides = config.colorOverrides;
                };
            in
              pkgs.runCommand "obsidianChroma" {} ''
                mkdir -p $out
                cp -r ${./theme}/manifest.json $out/manifest.json
                cp ${dynamicPalette} $out/theme.css
              '';
          };
        };

        reloadCommand = let
          obsidian-remote-cli = origin.inputs.obsidian-remote.packages.${pkgs.system}.default;
        in
          lib.mkForce "${obsidian-remote-cli}/bin/obsidian-remote run-command app:reload";
      };
    };

    imports = [
      (
        mkIf (cfg.enable && cfg.obsidian.enable) {
          programs.obsidian = {
            config = {
              plugins = [
                vendor.obsidian-remote.plugin
              ];
              appearance = {
                enable = true;
                cssTheme = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/chroma/active/obsidian/obsidianChroma";
              };
            };
          };
        }
      )
    ];
  }
