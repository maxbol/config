{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    theme-config.dunst.enable = mkOption {
      type = types.bool;
      default = config.services.dunst.enable;
      example = false;
      description = ''
        Whether to enable Dunst theming as part of Chroma.
      '';
    };
  };

  config = {
    theme-config.programs.dunst = {
      themeConfig = {opts, ...}: {
        file."dunstrc".text = ''
          [global]
              ### Icons ###

              # Recursive icon lookup. You can set a single theme, instead of having to
              # define all lookup paths.
              enable_recursive_icon_lookup = true

              # Set icon theme (only used for recursive icon lookup)
              # You can also set multiple icon themes, with the leftmost one being used first.
              icon_theme = ${opts.desktop.iconTheme.name}
        '';
      };
    };
  };

  imports = [
    (mkIf (config.theme-config.enable && config.theme-config.dunst.enable) {
      assertions = [
        {
          assertion = config.theme-config.desktop.enable;
          message = "Chroma's desktop module is required for the Dunst module.";
        }
      ];
      theme-config.desktop.enable = true;

      xdg.configFile."dunst/dunstrc.d/50-chroma".source = config.lib.file.mkOutOfStoreSymlink "${config.theme-config.themeDirectory}/active/dunst/dunstrc";
    })
  ];
}
