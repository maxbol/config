{
  config,
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
      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }";

      push = {
        autoSetupRemote = true;
      };
    };
  };

  sops = {
    secrets.github_packages_token = {
      path = "${config.xdg.configHome}/.github_packages_token";
    };

    templates.".gitconfig" = {
      path = "${config.home.homeDirectory}/.gitconfig";
      content = ''
        [url "https://maxbol:${config.sops.placeholder.github_packages_token}@github.com/ourstudio-se"]
                insteadOf = "https://github.com/ourstudio-se"

        [url "https://maxbol:${config.sops.placeholder.github_packages_token}@github.com/volvo-cars-se"]
                insteadOf = "https://github.com/volvo-cars-se"
      '';
    };
  };
}
