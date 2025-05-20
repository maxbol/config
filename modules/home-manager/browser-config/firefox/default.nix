{
  config,
  origin,
  pkgs,
  lib,
  lib-mine,
  ...
}: let
  unstable-pkgs = origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
  extensions = config.nur.repos.rycee.firefox-addons;

  profileName = "default";

  firefox-unmodified =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then unstable-pkgs.firefox-unwrapped
    else pkgs.firefox;

  customJsForFx = pkgs.fetchFromGitHub {
    owner = "Aris-t2";
    repo = "CustomJSForFx";
    rev = "4218e39d802d5852563d4da6e4c88ae91645b5cb";
    hash = "sha256-2Y9wso3nz3kdbfzl8Fk/qhL/v0epitrHUhHCjCKYsQ4=";
  };

  resourcesPath =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then "/Applications/Firefox.app/Contents/Resources"
    else "/lib/firefox";

  startupCachePath =
    if pkgs.stdenv.hostPlatform.isDarwin == true
    then "${config.home.homeDirectory}/Library/Caches/Firefox/Profiles/${profileName}/startupCache"
    else "${config.home.homeDirectory}/.cache/mozilla/firefox/${profileName}/startupCache";

  firefox = lib.makeOverridable (attrs: let
    f =
      if pkgs.stdenv.hostPlatform.isDarwin == true
      then firefox-unmodified
      else
        (
          if attrs != {}
          then firefox-unmodified.override attrs
          else firefox-unmodified
        );
  in (pkgs.runCommand "firefox-with-customjs" {} ''
    RESOURCES="$out${resourcesPath}"

    cp -R ${f} $out
    chmod -R u+w $RESOURCES
    cp ${customJsForFx}/script_loader/firefox/config.js "$RESOURCES/config.js"
    rm -R "$RESOURCES/defaults"
    cp -R ${customJsForFx}/script_loader/firefox/defaults "$RESOURCES/defaults"
    chmod -R u-w $RESOURCES
  '')) {};

  firefoxMacOSCmd = pkgs.writeShellScriptBin "firefox" ''
    cd ${firefox}/Applications/Firefox.app/Contents/MacOS
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
        package = firefox;
        profiles = {
          ${profileName} = {
            isDefault = true;
            settings = {
              "svg.context-properties.content.enabled" = true;
              "shyfox.enable.ext.mono.toolbar.icons" = true;
              "shyfox.enable.ext.mono.context.icons" = true;
              "shyfox.enable.context.menu.icons" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              # "general.config.filename" = "mozilla.cfg";
              # "general.config.obscure_value" = 0;
              "devtools.chrome.enabled" = true;
              "devtools.debugger.remote-enabled" = true;
              # "general.config.obscure_value" = 0;
              # "general.config.filename" = "config.js";
              # "general.config.sandbox_enabled" = false;
            };
            extensions = with extensions; [
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
        # copyOnActivation = true;
        config = {
          displayNavButtons = true;
          displaySidebarTools = true;
          displayTitles = false;
          font = {
            family = "Iosevka";
            size = "18px";
          };
        };
      };

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
          cp ${customJsForFx}/script_loader/firefox/config.js "$CHROME_DIR/config.js"
          chmod u+w "$PROFILE_DIR/config.js"
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
