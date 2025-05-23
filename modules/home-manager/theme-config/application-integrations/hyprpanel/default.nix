{
  config,
  lib,
  lib-mine,
  pkgs,
  ...
}: let
  cfg = config.theme-config;
  hyprpanel-cfg = config.programs.hyprpanel;
  inherit (lib-mine.types) colorType;
in {
  options = with lib; {
    theme-config.hyprpanel.enable = mkOption {
      type = types.bool;
      default = false;
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

        flatSet = lib.attrsets.recursiveUpdate (hyprpanel-cfg.settings or {}) theme;

        mergeSet = flatSet // hyprpanel-cfg.override;

        fullSet =
          if hyprpanel-cfg.settings.layout == null
          then mergeSet
          else mergeSet // hyprpanel-cfg.settings.layout;
      in {
        text = builtins.toJSON fullSet;
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
          assertion = !config.programs.hyprpanel.config.enable;
          message = "Hyprpanel home manager module must not have config.enable=true when used with theme integration";
        }
      ];

      xdg.configFile.hyprpanel = makeLink "hyprpanel/config.json";
      xdg.configFile.hyprpanel-swap = makeLink "hyprpanel/config.hm.json";
    }))
  ];
}
