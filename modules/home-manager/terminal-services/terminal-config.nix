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
        home.packages = [
          pkgs.nerd-fonts.symbols-only
          pkgs.xdg-terminal-exec
          # Necessary for Nautilus and other GNOME apps to correctly use kitty to open .desktop files with Terminal=true
          pkgs.imagemagick
        ];
        programs.kitty = {
          enable = true;
          package = nixpkgs-unstable.kitty;
          settings = {
            background_blur = 10;
            text_composition_strategy = "3 0";
            # text_composition_strategy = "platform";
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
            # cursor_trail = 3;
            open_url_with = "default";
            wheel_scroll_multiplier = 0.5;
            touchpad_scroll_multiplier = 0.5;
            symbol_map = let
              mappings = [
                "U+23FB-U+23FE"
                "U+2500-U+259F"
                "U+2630"
                "U+2665"
                "U+26A1"
                "U+276C-U+2771"
                "U+2B58"
                "U+E000-U+E00A"
                "U+E0A0-U+E0A3"
                "U+E0B0-U+E0BF"
                "U+E0C0-U+E0C8"
                "U+E0CA"
                "U+E0CC-U+E0D7"
                "U+E200-U+E2A9"
                "U+E300-U+E3E3"
                "U+E5FA-U+E6B7"
                "U+E700-U+E8EF"
                "U+EA60-U+EC1E"
                "U+ED00-U+EFCE"
                "U+EE00-U+EE0B"
                "U+F000-U+F2FF"
                "U+F300-U+F381"
                "U+F400-U+F533"
                "U+F0001-U+F1AF0"
              ];
            in
              (builtins.concatStringsSep "," mappings) + " Symbols Nerd Font Mono";
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
