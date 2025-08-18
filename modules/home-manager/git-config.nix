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
      # url = {
      #   "git@github.com".insteadOf = "https://github.com";
      #   "git@gitlab.com".insteadOf = "https://gitlab.com";
      # };

      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }";

      push = {
        autoSetupRemote = true;
      };
    };
  };
}
