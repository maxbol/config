{
  config,
  lib,
  lib-mine,
  origin,
  pkgs,
  self,
  vendor,
  ...
}: let
  # pkgs-unstable = origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
  lib-mine.mkFeature "features.linux-desktop.shell" {
    imports = [
      origin.inputs.noctalia.homeModules.default
      origin.inputs.dms.homeModules.dank-material-shell
    ];

    config = {
      # programs.noctalia-shell = {
      #   enable = true;
      #   systemd.enable = true;
      # };

      programs.dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;
        systemd.enable = true;
        # Keeps matugen off the PATH so dms doesn't try to generate GTK/Qt
        # system themes on every theme switch (Chroma owns those files as
        # read-only store links, so generation would fail with an OSD error).
        enableDynamicTheming = false;
      };

      home.packages = [
        vendor.dankcalendar.default
      ];

      # dankcalendar has no module of its own to hang this off of.
      theme-config.dankcal.enable = true;

      # Chroma theme switcher, reachable in the launcher under the #theme
      # trigger. Replaces the rofi themeselect script.
      programs.dank-material-shell.plugins.chromaThemes.src = self.dms-chroma-themes;

      # A running dms scans for plugins only at startup: neither adding a
      # plugin nor `plugin-scan rescan`/`reload` makes it pick up a surface the
      # manifest did not have when it started. Restarting on a plugin change is
      # what actually applies one, and sd-switch does that from this trigger.
      systemd.user.services.dms.Unit.X-RestartTriggers = [self.dms-chroma-themes];

      # dms loads a plugin only when it is enabled in plugin_settings.json, and
      # that file is not managed declaratively: doing so would take the file
      # over entirely and drop the plugins installed through dms itself. So the
      # flag is merged in instead. dms watches the file, so this applies live.
      home.activation.enableChromaThemesPlugin = let
        settings = "${config.xdg.configHome}/DankMaterialShell/plugin_settings.json";
        jq = lib.getExe pkgs.jq;
      in
        # Before sd-switch restarts dms (which happens after
        # linkGeneration), so the shell comes back up with the flag set.
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          mkdir -p "$(dirname "${settings}")"
          if ! [[ -s "${settings}" ]]; then
            echo '{}' > "${settings}"
          fi

          if ! ${jq} -e '.chromaThemes.enabled == true' "${settings}" > /dev/null; then
            ${jq} '.chromaThemes.enabled = true' "${settings}" > "${settings}.chroma"
            mv -f "${settings}.chroma" "${settings}"
          fi

        '';

      # home.packages = [
      #   pkgs-unstable.quickshell
      # ];
    };
  }
