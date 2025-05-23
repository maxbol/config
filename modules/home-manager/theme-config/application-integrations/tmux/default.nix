{
  config,
  lib,
  lib-mine,
  pkgs,
  ...
}:
with lib; let
  cfg = config.theme-config;

  inherit (lib-mine.types) colorType;
in {
  options = {
    theme-config.tmux.enable = mkOption {
      type = types.bool;
      default = config.programs.tmux.enable;
      example = false;
      description = ''
        Whether to enable tmux themeing as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.enable || config.programs.tmux.enable;
        message = "Tmux Chroma integration only works when the tmux home-manager module is enabled.";
      }
    ];

    theme-config.programs.tmux = {
      themeOptions = {
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
      }: {
        file."tinted-tmux-statusline.conf" = {
          required = true;
          source = mkDefault (opts.palette.generateDynamic {
            template = ./tinted-tmux-statusline.conf.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };
      };

      reloadCommand = "${lib.getExe pkgs.tmux} source ${config.xdg.configHome}/tmux/tmux.conf";
    };
  };

  # imports = [
  #   (mkIf (cfg.enable && cfg.tmux.enable) {
  #     programs.tmux.extraConfig = ''
  #       set -gq @tinted-tmux-modulepane-right-outer "󱃾 #( KUBE_TMUX_NS_ENABLE=false KUBE_TMUX_SYMBOL_ENABLE=false ${kube-tmux}/kube.tmux )"
  #       set -gqa @tinted-tmux-modulepane-right-outer "  "
  #       set -gqa @tinted-tmux-modulepane-right-outer "󰥔 #( ${clockifyd}/bin/clockifyd-get-current )"
  #       set -gqF @tinted-tmux-modulepane-right-inner "%H:%M"
  #
  #       source ${config.xdg.configHome}/chroma/active/tmux/tinted-tmux-statusline.conf
  #     '';
  #   })
  # ];
}
