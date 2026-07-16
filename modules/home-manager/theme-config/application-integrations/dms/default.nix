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

  dmsThemesDirectory = "${config.xdg.configHome}/DankMaterialShell/themes";
  dmsSettingsFile = "${config.xdg.configHome}/DankMaterialShell/settings.json";
in {
  options = {
    theme-config.dms = {
      enable = mkOption {
        type = types.bool;
        default = config.programs.dank-material-shell.enable;
        example = false;
        description = ''
          Whether to enable DankMaterialShell themeing as part of Chroma.
        '';
      };
    };
  };

  config = {
    theme-config.programs.dms = {
      themeOptions = {
        stockTheme = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Use one of the stock themes shipped with dms (e.g. "purple")
            instead of generating one from the palette.
          '';
        };

        luminance = mkOption {
          type = types.enum ["dark" "light"];
          default = "dark";
          description = ''
            Whether dms should render this theme in dark or light mode.
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
      in
        mkIf (config.stockTheme == null) {
          file."theme.json" = {
            required = true;
            text = builtins.toJSON {
              name = config.themeName;
              dark = colorsJson;
              light = colorsJson;
            };
          };
        };

      activationCommand = {
        name,
        opts,
        ...
      }: let
        settingsUpdate =
          if opts.stockTheme != null
          then ''.currentThemeName = "${opts.stockTheme}" | .currentThemeCategory = "generic"''
          else ''.currentThemeName = "custom" | .currentThemeCategory = "custom" | .customThemeFile = "${dmsThemesDirectory}/${name}/theme.json"'';
      in ''
        # dms watches settings.json and hot-applies external edits, including
        # switching to the theme file named in customThemeFile. It has no ipc
        # for theme selection, only for luminance.
        mkdir -p "${dirOf dmsSettingsFile}"
        if [[ -s "${dmsSettingsFile}" ]]; then
          ${getExe pkgs.jq} '${settingsUpdate}' \
            "${dmsSettingsFile}" > "${dmsSettingsFile}.chroma"
          mv "${dmsSettingsFile}.chroma" "${dmsSettingsFile}"
        else
          echo '{}' | ${getExe pkgs.jq} '${settingsUpdate}' > "${dmsSettingsFile}"
        fi

        dms ipc call theme ${opts.luminance} > /dev/null 2>&1 || true
      '';
    };
  };

  imports = [
    (
      mkIf (cfg.enable && cfg.dms.enable)
      {
        # Copy (rather than link) the theme files so that the file watcher in
        # dms picks up changed colors for the active theme: it follows links
        # to the (immutable) store inode and would never fire again.
        home.activation.copyDmsThemes = lib.hm.dag.entryAfter ["linkChromaDefault"] ''
          for theme in ${cfg.themeDirectory}/themes/*; do
            themeName=$(basename $theme)
            source="$theme/dms/theme.json"
            targetDir="${dmsThemesDirectory}/$themeName"
            target="$targetDir/theme.json"
            if [[ -f "$source" ]]; then
              mkdir -p "$targetDir"
              # Plain cp would carry over the read-only mode of the store file,
              # making the next overwrite fail; install replaces the target and
              # forces a writable mode.
              install -m 644 "$source" "$target.tmp"
              mv -f "$target.tmp" "$target"
            else
              [[ -d "$targetDir" ]] && rm -Rf "$targetDir"
            fi
          done
        '';
      }
    )
  ];
}
