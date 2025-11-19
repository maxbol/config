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
      unshallow = ''!git fetch --unshallow && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && git fetch origin'';
    };

    extraConfig = {
      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }";

      merge = {
        conflictStyle = "diff3";
      };

      push = {
        autoSetupRemote = true;
      };
    };
  };

  sops = {
    secrets.github_packages_token = {
      path = "${config.xdg.configHome}/.github_packages_token";
    };

    secrets.github_vcc_token = {};

    templates.".gitconfig" = {
      path = "${config.home.homeDirectory}/.gitconfig";
      content = ''
        [url "https://maxbol:${config.sops.placeholder.github_packages_token}@github.com/ourstudio-se"]
                insteadOf = "https://github.com/ourstudio-se"

        [url "https://maxbol:${config.sops.placeholder.github_packages_token}@github.com/volvo-cars-se"]
                insteadOf = "https://github.com/volvo-cars-se"

        [url "https://maxbol:${config.sops.placeholder.github_vcc_token}@github.com/volvo-cars"]
                insteadOf = "https://github.com/volvo-cars"
      '';
    };
  };
}
