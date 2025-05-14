{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.git-config" {
  home.packages = [pkgs.gh];

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;

    aliases = {
      adog = "log --all --decorate --oneline --graph";
    };

    extraConfig = {
      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }";

      push = {
        autoSetupRemote = true;
      };
    };
  };
}
