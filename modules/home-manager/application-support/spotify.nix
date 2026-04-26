{
  lib-mine,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.application-support.spotify" (let
  spicetify-nix = origin.inputs.spicetify-nix;
  pkgs-spicetify-nix = spicetify-nix.legacyPackages.${pkgs.system};
in {
  imports = [
    spicetify-nix.homeManagerModules.default
  ];

  config = {
    programs.spicetify = {
      enable = true;
      theme = let
        text-theme = pkgs-spicetify-nix.themes.text;
      in
        pkgs-spicetify-nix.themes.text;
      # colorScheme = "RosePine";
    };

    xdg.configFile."spicetify/colors.ini" = {
      text = ''

      '';
    };
  };
})
