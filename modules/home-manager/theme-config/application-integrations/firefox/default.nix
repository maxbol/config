{
  lib,
  config,
  pkgs,
  lib-mine,
  ...
}: let
  inherit (lib-mine.types) colorType;

  cfg = config.theme-config;
in {
  options = {
    theme-config.firefox = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.programs.firefox.enable && config.textfox.enable;
        example = false;
        description = ''
          Whether to enable Firefox settings as part of Chroma.
        '';
      };

      profile = lib.mkOption {
        type = lib.types.str;
        example = "default";
        default = config.textfox.profile;
        description = ''
          The name of the Firefox profile to apply the themeing to.
        '';
      };

      package = lib.mkOption {
        type = lib.types.path;
        example = "pkgs.firefox";
        default = config.programs.firefox.package;
        description = ''
          Path to the installed firefox package
        '';
      };

      copyOnActivation = lib.mkOption {
        type = lib.types.bool;
        default = config.textfox.copyOnActivation;
      };

      vimiumFontFamily = lib.mkOption {
        type = lib.types.str;
        example = "Iosevka";
        default = config.textfox.config.font.family or "Arial";
        description = ''
          Font family to apply to vimium omnibar and hints. Defaults to the same font as is used in textfox config.
        '';
      };
    };
  };

  config = {
    theme-config.programs.firefox = {
      themeOptions = {
        enableColors = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''Wether to apply theme colors to firefox chrome and omnibar'';
        };
        enableSiteColors = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''Wether to apply theme colors to a select number of sites'';
        };
        colorOverrides = lib.mkOption {
          type = lib.types.attrsOf colorType;
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
        chromeColorsCss = opts.palette.generateDynamic {
          template = ./colors.css.dyn;
          paletteOverrides = config.colorOverrides;
        };

        siteColorsCss = opts.palette.generateDynamic {
          template = ./sitecolors.css.dyn;
          paletteOverrides = config.colorOverrides;
        };

        colorsCss = pkgs.writeText "colors.css" (lib.strings.concatStringsSep "\n" [
          (
            if config.enableColors == true
            then (builtins.readFile chromeColorsCss)
            else ""
          )
          (
            if config.enableSiteColors == true
            then (builtins.readFile siteColorsCss)
            else ""
          )
        ]);
      in {
        file."colors.css" = lib.mkIf (cfg.firefox.copyOnActivation == false) {
          required = true;
          source = lib.mkDefault colorsCss;
        };

        file."setcolors.sh" = let
          profileDir =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "Library/Application\ Support/Firefox/Profiles"
            else ".mozilla/firefox";
        in
          lib.mkIf (cfg.firefox.copyOnActivation) {
            required = true;
            source = lib.mkDefault (pkgs.writeScript "setcolors.sh" ''
              profile_dir="$HOME/${profileDir}/${cfg.firefox.profile}"
              chrome_dir="$profile_dir/chrome"
              mkdir -p "$chrome_dir"

              cp ${colorsCss} "$chrome_dir/colors.css"
              chown -R $USER "$chrome_dir/colors.css"
              chmod 644 "$chrome_dir/colors.css"
            '');
          };
      };

      reloadCommand = lib.mkIf cfg.firefox.copyOnActivation "~/.config/chroma/active/firefox/setcolors.sh";
    };
  };

  imports = [
    (lib.mkIf
      (cfg.enable && cfg.firefox.enable)
      {
        textfox = {
          config = {
            customCss = ''
              @import url("${
                if cfg.firefox.copyOnActivation
                then "colors.css"
                else "${config.xdg.configHome}/chroma/active/firefox/colors.css"
              }");

              :root {
                --vimium-font-family: "${cfg.firefox.vimiumFontFamily}" !important;
              }
            '';
          };
        };
      })
  ];
}
