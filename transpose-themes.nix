{
  flake-parts,
  self,
}: ({lib, ...}: (
  flake-parts.lib.mkTransposedPerSystemModule {
    name = "themes";
    file = ./flake.nix;
    option = lib.mkOption {
      type =
        (lib.evalModules {
          modules = [
            self.homeManagerModules.themeConfig
            {_module.check = false;}
          ];
        })
        .options
        .theme-config
        .themes
        .type;
      default = {};
      description = ''
        A set of themes for the themeing system to use.
      '';
    };
  }
))
