{
  lib-mine,
  self,
  pkgs,
  lib,
  ...
}: let
  zathura-darwin = self.zathura-darwin;
  zathura-darwin-app = self.zathura-darwin-app;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin == true;
in
  lib-mine.mkFeature "features.application-support.zathura" {
    programs.zathura = {
      enable = true;
      package =
        if isDarwin
        then zathura-darwin
        else pkgs.zathura;
    };

    home.activation.copyZathuraApp = let
      dest = "$HOME/Applications/zathura-darwin.app";
    in
      lib.mkIf isDarwin (
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          rm -rf $HOME/Applications/zathura-client.app
          cp -LR ${zathura-darwin-app}/Applications/zathura-darwin.app ${dest}
          chmod -R ug+rwx ${dest}
        ''
      );
  }
