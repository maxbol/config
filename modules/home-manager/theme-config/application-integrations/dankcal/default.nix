{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.theme-config;

  dankcalConfigDirectory = "${config.xdg.configHome}/dankcal";
  dankcalSettingsFile = "${dankcalConfigDirectory}/ui-settings.json";

  # dankcalendar resolves this path once and then watches the inode it landed
  # on, so it has to be a real file that is rewritten in place. Pointed at the
  # theme in the Chroma directory instead, it would follow the "active" symlink
  # into the (immutable) store and never see another change: switching themes
  # only repoints a symlink above the file it is watching.
  dankcalThemeFile = "${dankcalConfigDirectory}/chroma-theme.json";
in {
  options = {
    theme-config.dankcal.enable = mkEnableOption "dankcalendar theming as part of Chroma";
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.dankcal.enable) || cfg.dms.enable;
        message = "The dankcalendar Chroma integration reuses the colors of the DankMaterialShell integration, which has to be enabled as well.";
      }
    ];

    theme-config.programs.dankcal = {
      # dankcalendar reads the theme file format of DankMaterialShell, so the
      # colors generated for dms are used as they are.
      themeConfig = {opts, ...}:
        mkIf (opts.dms.file ? "theme.json") {
          file."theme.json".source = opts.dms.file."theme.json".source;
        };

      activationCommand = {opts, ...}:
        optionalString (opts.file ? "theme.json") ''
          # Rewriting the file dankcalendar already watches is what makes it
          # pick up the new colors; a symlink to the store would not change.
          mkdir -p "${dankcalConfigDirectory}"
          # Plain cp would carry over the read-only mode of the store file,
          # making the next overwrite fail; install forces a writable mode.
          install -m 644 "${opts.file."theme.json".source}" "${dankcalThemeFile}.chroma"
          mv -f "${dankcalThemeFile}.chroma" "${dankcalThemeFile}"
        '';
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.dankcal.enable) {
      # Which file to read is not part of a theme, so it is set once instead of
      # on every theme switch. dankcalendar watches its settings and applies
      # external edits, so this takes effect while it is running.
      home.activation.pointDankcalAtChroma = hm.dag.entryAfter ["linkChromaDefault"] ''
        mkdir -p "${dankcalConfigDirectory}"
        if ! [[ -s "${dankcalSettingsFile}" ]]; then
          echo '{}' > "${dankcalSettingsFile}"
        fi

        # Only write when something actually differs: dankcalendar reloads its
        # settings whenever the file changes.
        if ! ${getExe pkgs.jq} -e \
          '.colorSource == "custom" and .customThemeFile == "${dankcalThemeFile}"' \
          "${dankcalSettingsFile}" > /dev/null; then
          ${getExe pkgs.jq} \
            '.colorSource = "custom" | .customThemeFile = "${dankcalThemeFile}"' \
            "${dankcalSettingsFile}" > "${dankcalSettingsFile}.chroma"
          mv -f "${dankcalSettingsFile}.chroma" "${dankcalSettingsFile}"
        fi
      '';
    })
  ];
}
