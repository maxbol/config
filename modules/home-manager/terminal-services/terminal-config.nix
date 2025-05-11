{
  config,
  lib,
  pkgs,
  origin,
  ...
}: let
  cfg = config.features;
  nixpkgs-unstable = origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in {
  options = with lib; {
    features.terminal-services.terminal-config = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  imports = [
    (
      lib.mkIf
      (cfg.terminal-services.terminal-config.enable)
      {
        programs.kitty = {
          enable = true;
          package = nixpkgs-unstable.kitty;
          settings = {
            background_blur = 10;
            dynamic_background_opacity = "yes";
            hide_window_decorations =
              if pkgs.stdenv.hostPlatform.isDarwin
              then "titlebar-only"
              else "yes";
            window_margin_width = 5;
            window_padding_width = 5;
            background_opacity = "1";
            modify_font = "cell_height 120%";
            confirm_os_window_close = 0;
            placement_strategy = "top-left";
            cursor_trail = 3;
          };
          keybindings = {
            "cmd+h" = "";
            "cmd+k" = "";
          };
        };
      }
    )
  ];
}
