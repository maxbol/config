{
  config,
  lib,
  lib-mine,
  pkgs,
  options,
  ...
}: let
  cfg = config.theme-config;
  inherit (lib-mine.types) colorType;
in {
  options = with lib; {
    theme-config.hyprpanel = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      settings =
        options.programs.hyprpanel.settings
        // {
          default = {};
        };
    };
  };

  config.theme-config.programs.hyprpanel = {
    themeOptions = with lib; {
      colorOverrides = mkOption {
        type = types.attrsOf colorType;
        default = {};
      };

      theme = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            package = mkOption {type = types.either types.str types.path;};
            name = mkOption {type = types.str;};
          };
        });
        default = null;
      };
    };

    themeConfig = {
      config,
      opts,
      ...
    }: {
      file."config.json" = let
        themeFile =
          if config.theme != null
          then "${config.theme.package}/share/themes/${config.theme.name}.json"
          else "${opts.palette.generateDynamic {
            template = ./config.json.dyn;
            paletteOverrides = config.colorOverrides;
          }}";

        theme = builtins.fromJSON (builtins.readFile themeFile);

        set = lib.attrsets.recursiveUpdate (cfg.hyprpanel.settings or {}) theme;
      in {
        text = builtins.toJSON set;
      };
    };

    reloadCommand = "${pkgs.procps}/bin/pkill -SIGUSR1 hyprpanel";
  };

  imports = [
    (lib.mkIf (cfg.enable && cfg.hyprpanel.enable) (let
      makeLink = target: {
        inherit target;
        source = config.lib.file.mkOutOfStoreSymlink "${config.theme-config.themeDirectory}/active/hyprpanel/config.json";
      };
    in {
      assertions = [
        {
          assertion = config.programs.hyprpanel.enable;
          message = "Hyprpanel must be enabled in order to use the hyprpanel theme integration";
        }
        {
          assertion = config.programs.hyprpanel.settings == {};
          message = "Hyprpanel home manager module must have settings set to {}";
        }
      ];

      xdg.configFile.hyprpanel = makeLink "hyprpanel/config.json";
      xdg.configFile.hyprpanel-swap = makeLink "hyprpanel/config.hm.json";
    }))
  ];
}
