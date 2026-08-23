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

  # Vicinae merges every file in VICINAE_OVERRIDES over its own settings.json,
  # with the last one winning, so this is where the active theme is recorded.
  # Writing settings.json directly is not an option: vicinae rewrites it with a
  # comment header whenever it changes a setting itself, and it is read as jsonc.
  vicinaeOverrideFile = "${config.xdg.configHome}/vicinae/chroma.json";

  # Vicinae scans this directory (relative to the XDG data home) for *.toml
  # theme files and takes the file name as the id of the theme it defines.
  vicinaeThemesDirectory = "vicinae/themes";

  # Themes that point at a theme shipped with vicinae generate no file of
  # their own and must not be linked into the themes directory.
  generatedThemes = filterAttrs (_: theme: theme.vicinae.stockTheme == null) cfg.finalThemes;
in {
  options = {
    theme-config.vicinae.enable = mkOption {
      type = types.bool;
      default = config.programs.vicinae.enable;
      example = false;
      description = ''
        Whether to enable vicinae theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.vicinae.enable) || config.programs.vicinae.enable;
        message = "Vicinae Chroma integration only works when the base Vicinae module is enabled.";
      }
    ];

    warnings = optional (cfg.enable && cfg.vicinae.enable && (config.programs.vicinae.settings.theme or {}) != {}) ''
      The theme set in "programs.vicinae.settings" is overridden by the Chroma
      integration, which owns the vicinae theme while it is enabled.
    '';

    theme-config.programs.vicinae = {
      themeOptions = {
        stockTheme = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "vicinae-dark";
          description = ''
            Use a theme that vicinae already knows about (e.g. "vicinae-dark")
            instead of generating one from the palette.
          '';
        };

        variant = mkOption {
          type = types.enum ["dark" "light"];
          defaultText = literalExpression ''"light" if the gtk color scheme prefers light, "dark" otherwise'';
          description = ''
            Whether this is a dark or a light theme. Vicinae uses this both to
            pick an icon for the theme and to decide how to derive hover colors.
          '';
        };

        inherits = mkOption {
          type = types.str;
          defaultText = literalExpression ''"vicinae-''${variant}"'';
          description = ''
            The theme that colors left undefined by this one are taken from.
            This is either one of the two themes built into vicinae or the id
            of another theme that is installed.
          '';
        };

        description = mkOption {
          type = types.str;
          defaultText = literalExpression ''"The ''${themeName} Chroma theme"'';
          description = ''
            The description vicinae shows for this theme in its theme picker.
          '';
        };

        iconTheme = mkOption {
          type = types.nullOr types.str;
          default = null;
          defaultText = literalExpression "the icon theme of the desktop module";
          example = "Tela-blue";
          description = ''
            The icon theme vicinae should use for application icons. Defaults
            to the icon theme of the desktop module when that one is enabled.
            Null leaves vicinae to guess one on its own.
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
        # Themes that are not generated from the palette are referred to by the
        # id vicinae knows them under; generated ones by the name of the file
        # they are linked as, which is the name of the Chroma theme.
        themeId =
          if config.stockTheme != null
          then config.stockTheme
          else config.themeName;

        themeSettings =
          {name = themeId;}
          // optionalAttrs (config.iconTheme != null) {icon_theme = config.iconTheme;};
      in {
        variant = mkDefault (
          if opts.gtk.colorScheme == "prefer-light"
          then "light"
          else "dark"
        );
        inherits = mkDefault "vicinae-${config.variant}";
        description = mkDefault "The ${config.themeName} Chroma theme";
        iconTheme = mkIf cfg.desktop.enable (mkDefault (opts.desktop.iconTheme.name or null));

        # Which of the two variants vicinae reads depends on the color scheme
        # the system reports, but the active Chroma theme applies either way.
        file."settings.json" = {
          required = true;
          text = builtins.toJSON {
            theme = {
              light = themeSettings;
              dark = themeSettings;
            };
          };
        };

        file."theme.toml" = mkIf (config.stockTheme == null) {
          required = true;

          # The palette only covers the colors, so the [meta] table that
          # vicinae requires is prepended to the generated file.
          source = let
            meta = pkgs.writeText "vicinae-meta.toml" ''
              [meta]
              name = ${builtins.toJSON config.themeName}
              description = ${builtins.toJSON config.description}
              variant = ${builtins.toJSON config.variant}
              inherits = ${builtins.toJSON config.inherits}

            '';

            colors = opts.palette.generateDynamic {
              template = ./theme.toml.dyn;
              paletteOverrides = config.colorOverrides;
            };
          in
            mkDefault (pkgs.concatText "vicinae-${hm.strings.storeFileName config.themeName}-theme.toml" [meta colors]);
        };
      };

      activationCommand = {opts, ...}: ''
        # vicinae watches the files it takes settings from and reloads them in
        # place, so replacing this one is all a theme switch takes.
        mkdir -p "${dirOf vicinaeOverrideFile}"
        # Plain cp would carry over the read-only mode of the store file,
        # making the next overwrite fail; install forces a writable mode.
        install -m 644 "${opts.file."settings.json".source}" "${vicinaeOverrideFile}.chroma"
        mv -f "${vicinaeOverrideFile}.chroma" "${vicinaeOverrideFile}"
      '';
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.vicinae.enable) {
      programs.vicinae.settingOverrides = [vicinaeOverrideFile];

      # Every theme is installed at once, so that activating one only has to
      # name it. Vicinae watches the directory and reparses what changed.
      xdg.dataFile = mapAttrs' (themeName: _:
        nameValuePair "${vicinaeThemesDirectory}/${themeName}.toml" {
          source = "${cfg.themePackages.${themeName}}/vicinae/theme.toml";
        })
      generatedThemes;

      # Override files that do not exist when vicinae loads its config are
      # skipped and not watched, so seed ours before the service starts.
      home.activation.seedVicinaeSettings = hm.dag.entryBetween ["reloadSystemd" "setupLaunchAgents"] ["linkChromaDefault"] ''
        mkdir -p "${dirOf vicinaeOverrideFile}"
        if ! [ -e "${vicinaeOverrideFile}" ] && [ -e "${cfg.themeDirectory}/active/vicinae/settings.json" ]; then
          install -m 644 "${cfg.themeDirectory}/active/vicinae/settings.json" "${vicinaeOverrideFile}"
        fi
      '';
    })
  ];
}
