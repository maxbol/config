{
  pkgs,
  lib-mine,
  vendor,
  ...
}: let
  obsidian-remote-cli = vendor.obsidian-remote.default;
  monoFont = "Aporetic Sans Mono";
in
  lib-mine.mkFeature "features.application-support.obsidian" {
    config = {
      home.packages = with pkgs; [
        obsidian
        obsidian-remote-cli
        fira-code
      ];

      programs.obsidian = {
        enable = true;
        vaults = [
          "Notes/maxnotes"
        ];
        config = {
          appearance = {
            enable = true;
            interfaceFontFamily = monoFont;
            textFontFamily = monoFont;
            monospaceFontFamily = monoFont;
            baseFontSize = 18;
          };
        };
      };
    };
  }
