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

  baseConfigFile = makeNiriConfig niri-cfg.package cfg.niri.baseConfig;

  # The extra parts are appended after validation of the base config, since
  # the theme include target only exists at runtime. The theme include comes
  # last so that theme values win over both the base config and the extra
  # config text (niri merges repeated sections field by field, later files
  # taking precedence).
  configFile = pkgs.runCommand "niri-config.kdl" {} ''
    cat ${baseConfigFile} ${pkgs.writeText "niri-config-extra.kdl" ''


      ${lib.optionalString (cfg.niri.extraConfigTxt != null) cfg.niri.extraConfigTxt}
      include "${cfg.themeDirectory}/active/niri/theme.kdl"
    ''} > $out
  '';
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
        description = ''
          The complete, theme-independent niri config - should be set globally
          for the niri installation. The per-theme theme.kdl is pulled in via
          an include at the end of the generated config.kdl.
        '';
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
        themeKdl = (import ./theme-template.nix) lib opts.palette config.colorOverrides;

        cursorKdl = lib.optionalString (opts.desktop.cursorTheme != null) ''
          environment {
              XCURSOR_THEME "${opts.desktop.cursorTheme.name}"
              XCURSOR_SIZE "${toString opts.desktop.cursorTheme.size}"
          }
        '';

        themeFile = pkgs.writeText "niri-theme.kdl" (themeKdl + cursorKdl);
      in {
        file."theme.kdl" = {
          required = true;
          source = pkgs.runCommand "niri-theme-validated.kdl" {} ''
            ${lib.getExe' niri-cfg.package "niri"} validate --config ${themeFile}
            cp ${themeFile} $out
          '';
        };
      };
    };
  };

  imports = [
    (
      lib.mkIf cfg.niri.enable {
        xdg.configFile."niri/config.kdl".source = configFile;
      }
    )
  ];
}
