{
  config,
  pkgs,
  lib,
  lib-mine,
  vendor,
  ...
}:
with lib; let
  cfg = config.theme-config;

  optionalPackage = opt:
    optional (opt != null && opt.package != null) opt.package;

  inherit (lib-mine.types) colorType;
in {
  options = {
    theme-config.ghostty.enable = mkOption {
      type = types.bool;
      default = config.programs.ghostty.enable;
      example = false;
      description = ''
        Whether to enable Ghostty theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.ghostty.enable) || config.programs.ghostty.enable;
        message = "Chroma Ghostty theming requires Ghostty to be enabled.";
      }
    ];

    theme-config.programs.ghostty = let
      pkill =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/usr/bin/pkill"
        else "${pkgs.procps}/bin/pkill";
    in {
      themeOptions = {
        font = mkOption {
          type = types.nullOr hm.types.fontType;
          default = {
            name = "JetBrainsMono Nerd Font";
            size = 12;
            package = pkgs.nerd-fonts.jetbrains-mono;
          };
          description = ''
            The font to use in ghostty.
          '';
        };
        autoGenerate = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };

              colorOverrides = mkOption {
                type = types.attrsOf colorType;
                default = {};
                description = ''
                  Color overrides to apply to the palette-generated theme.
                '';
              };
            };
          };
          default = {};
        };
      };

      themeConfig = {
        config,
        opts,
        ...
      }: {
        imports = [
          (
            mkIf config.autoGenerate.enable (
              let
                themeSource = opts.palette.generateDynamic {
                  template = ./theme.conf.dyn;
                  paletteOverrides = config.autoGenerate.colorOverrides;
                };
              in {
                file."theme.conf".source = themeSource;
              }
            )
          )
        ];

        file."fonts.conf" = {
          text =
            if config.font != null
            then ''
              font-family = ${config.font.name}
              font-size = ${toString config.font.size}
            ''
            else "";
        };
      };

      # Ghostty reloads its configuration on SIGUSR2 (since Ghostty 1.2).
      reloadCommand = mkForce "${pkill} -USR2 -u $USER ghostty || true";
    };

    # The `?` prefix marks the include as optional so Ghostty does not warn
    # when a theme does not auto-generate a color theme (fonts.conf is always
    # generated, so it is required).
    programs.ghostty.settings.config-file = mkIf (cfg.enable && cfg.ghostty.enable) [
      "?${config.theme-config.themeDirectory}/active/ghostty/theme.conf"
      "${config.theme-config.themeDirectory}/active/ghostty/fonts.conf"
    ];
  };

  imports = [
    (mkIf (cfg.enable && cfg.ghostty.enable) {
      home.packages = concatLists (mapAttrsToList (name: opts: with opts.ghostty; concatMap optionalPackage [font]) cfg.themes);
    })
  ];
}
