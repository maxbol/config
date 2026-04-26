{
  lib-mine,
  lib,
  origin,
  options,
  config,
  pkgs,
  ...
}: let
  cfg = config.theme-config;
  niri-cfg = config.programs.niri;

  makeNiriConfig = package: settings: let
    niri-nixpkgs = origin.inputs.niri.inputs.nixpkgs;
    eval = niri-nixpkgs.lib.evalModules {
      modules = [
        origin.inputs.niri.lib.internal.settings-module
        {
          config.programs.niri = {
            inherit settings;
          };
        }
      ];
    };
  in (
    origin.inputs.niri.lib.internal.validated-config-for
    niri-nixpkgs.legacyPackages.${pkgs.system}
    package
    eval.config.programs.niri.finalConfig
  );
in {
  options = with lib; {
    theme-config.niri = {
      enable = mkOption {
        type = types.bool;
        default = config.programs.niri.enable;
        description = ''Whether to enable niri styling as part of themeing integration'';
      };

      baseConfig = mkOption {
        type = types.attrs;
        default = {};
        description = ''Base config to apply to the config.kdl - should be set globally for the niri installation'';
      };

      extraConfigTxt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''Extra config as string to append at the end of the config file. Useful for when sodiboo is lazy with updating the niri flake.'';
      };
    };
  };

  config = {
    theme-config.programs.niri = {
      themeOptions = with lib; {
        themeSettings = mkOption {
          type = types.nullOr types.attrs;
          default = null;
        };

        # themeKdl = mkOption {
        #   type = types.nullOr (types.either types.str kdl.types.kdl-document);
        #   default = null;
        # };

        colorOverrides = mkOption {
          type = types.attrsOf lib-mine.types.colorType;
          default = {};
        };
      };

      themeConfig = {
        config,
        opts,
        ...
      }: let
        themeSettings =
          if config.themeSettings == null
          then ((import ./theme-template.nix) lib opts.palette config.colorOverrides)
          else config.themeSettings;

        settingsFile = makeNiriConfig niri-cfg.package (
          lib.mkMerge [
            cfg.niri.baseConfig
            themeSettings
          ]
        );

        mergedSettingsFile =
          if cfg.niri.extraConfigTxt == null
          then settingsFile
          else
            pkgs.runCommand "niri-config" {} ''
              touch $out
              cat ${settingsFile} >> $out
              cat >> $out << EOF

              ${cfg.niri.extraConfigTxt}
              EOF
            '';
      in {
        file."config.kdl".source = mergedSettingsFile;
      };
    };
  };

  imports = [
    (
      lib.mkIf cfg.niri.enable {
        xdg.configFile."niri/config.kdl".source = config.lib.file.mkOutOfStoreSymlink "${config.theme-config.themeDirectory}/active/niri/config.kdl";
      }
    )
  ];
}
