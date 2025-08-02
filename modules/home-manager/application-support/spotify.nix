{
  lib-mine,
  origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.application-support.spotify" {
  imports = [
    origin.inputs.spicetify-nix.homeManagerModules.default
  ];

  config = {
    programs.spicetify = {
      enable = true;
      theme = origin.inputs.spicetify-nix.legacyPackages.${pkgs.system}.themes.text;
    };
  };
}
