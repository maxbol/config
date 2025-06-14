{
  config,
  origin,
  pkgs,
  lib,
  lib-mine,
  ...
}: let
  extensions = config.nur.repos.rycee.firefox-addons;

  profileName = "default";

  customJsForFx = pkgs.fetchFromGitHub {
    owner = "Aris-t2";
    repo = "CustomJSForFx";
    rev = "4218e39d802d5852563d4da6e4c88ae91645b5cb";
    hash = "sha256-2Y9wso3nz3kdbfzl8Fk/qhL/v0epitrHUhHCjCKYsQ4=";
  };

  firefox-unwrapped = pkgs.firefox-bin-unwrapped.overrideAttrs (prev: {
    installPhase =
      prev.installPhase
      + ''
        resourceDir="$out${resourcesPath}"
        cp ${./config.js} "$resourceDir/config.js"
        rm -R "$resourceDir/defaults"
        mkdir -p "$resourceDir/defaults/pref"
        cp ${./config-prefs.js} "$resourceDir/defaults/pref/config-prefs.js"
      '';
  });

  resourcesPath =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then "/Applications/Firefox.app/Contents/Resources"
    else "/lib/firefox-bin-${lib.getVersion firefox-unwrapped}";

  startupCachePath =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then "${config.home.homeDirectory}/Library/Caches/Firefox/Profiles/${profileName}/startupCache"
    else "${config.home.homeDirectory}/.cache/mozilla/firefox/${profileName}/startupCache";

  package =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then firefox-unwrapped
    else
      (pkgs.wrapFirefox firefox-unwrapped {
        pname = "firefox-cjsfx-wrapped";
      })
      .overrideAttrs (prev: {
        buildCommand =
          lib.strings.replaceStrings [
            ''echo 'pref("general.config.filename", "mozilla.cfg");' > "$prefsDir/autoconfig.js"''
          ] [
            ''
              echo 'pref("general.config.filename", "config.js");' > "$prefsDir/autoconfig.js"
              echo 'pref("general.config.sandbox_enabled", false);' >> "$prefsDir/autoconfig.js"
            ''
          ]
          prev.buildCommand;
      });

  firefoxMacOSCmd = pkgs.writeShellScriptBin "firefox" ''
    cd ${package}/Applications/Firefox.app/Contents/MacOS
    ./firefox $@
  '';

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/Firefox/Profiles/"
    else ".mozilla/firefox/";

  autoReloadCssUCJS = ./autoReloadCss.uc.js;
  userChromeJS = ./userChrome.js;
in
  lib-mine.mkFeature "features.browser-config.firefox" {
    imports = [
      origin.inputs.nur.modules.homeManager.default
      origin.inputs.textfox.homeManagerModules.default
    ];

    config = {
      programs.firefox = {
        enable = true;
        inherit package;
        profiles = {
          ${profileName} = {
            isDefault = true;
            settings = {
              "svg.context-properties.content.enabled" = true;
              "shyfox.enable.ext.mono.toolbar.icons" = true;
              "shyfox.enable.ext.mono.context.icons" = true;
              "shyfox.enable.context.menu.icons" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "devtools.chrome.enabled" = true;
              "devtools.debugger.remote-enabled" = true;
              "browser.urlbar.showSearchSuggestionsFirst" = false;
            };
            extensions.packages = with extensions; [
              vimium
              ublock-origin
              brotab
              darkreader
            ];
          };
        };
      };

      textfox = {
        enable = true;
        profile = profileName;
        flattenCss = true;
        config = {
          displayNavButtons = true;
          displaySidebarTools = true;
          displayTitles = false;
          font = {
            family = "Aporetic Sans Mono";
            size = "18px";
          };
        };
      };

      theme-config.firefox.copyOnActivation = true;

      home.packages = with pkgs; [
        brotab
        # firefox
        # TODO(2025-05-10, Max Bolotin): Reactivate iosevka again once nodejs_20 builds on mac os
        # iosevka
        (lib.mkIf
          (pkgs.stdenv.hostPlatform.isDarwin == true)
          firefoxMacOSCmd)
      ];

      home.sessionVariables.BROWSER = "firefox";

      home.activation.installFirefoxJSLoader =
        lib.hm.dag.entryAfter ["linkGeneration"]
        /*
        bash
        */
        ''
          PROFILE_DIR="${config.home.homeDirectory}/${configDir}/${profileName}"
          CHROME_DIR="$PROFILE_DIR/chrome"
          cp -R ${customJsForFx}/script_loader/profile/userChrome "$CHROME_DIR"
          chmod -R u+w "$CHROME_DIR/userChrome"
          cp ${autoReloadCssUCJS} "$CHROME_DIR/userChrome/autoReloadCss.uc.js"
          chmod u+w "$CHROME_DIR/userChrome/autoReloadCss.uc.js"
          cp ${userChromeJS} "$CHROME_DIR/userChrome.js"
          chmod u+w "$CHROME_DIR/userChrome.js"
        '';

      home.activation.clearFirefoxStartupCache =
        lib.hm.dag.entryAfter ["linkGeneration"]
        /*
        bash
        */
        ''
          rm -Rf "${startupCachePath}"
        '';
    };
  }
