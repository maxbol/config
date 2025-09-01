{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.git-config" {
  home.packages = [pkgs.gh];

  programs.jujutsu = {
    enable = true;
  };

  programs.mergiraf = {
    enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;

    aliases = {
      adog = "log --all --decorate --oneline --graph";
    };

    extraConfig = {
      url = {
        "https://maxbol:xyz@github.com/volvo-cars-se".insteadOf = "https://github.com/volvo-cars-se";
        "https://maxbol:xyz@github.com/ourstudio-se".insteadOf = "https://github.com/ourstudio-se";
      };

      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }";

      push = {
        autoSetupRemote = true;
      };
    };
  };
}
