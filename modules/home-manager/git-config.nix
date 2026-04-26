{
  config,
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.git-config" {
  home.packages = with pkgs; [
    gh
    radicle-node
    radicle-desktop
    radicle-tui
  ];

  services.ssh-agent.enable = true;

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "maks.bolotin@gmail.com";
        name = "Max Bolotin";
      };
      aliases = {
        dlog = ["log" "-r"];
        l = ["l" "-r" "(trunk()..@):: | (trunk()..@)-"];
        fresh = ["new" "trunk()"];
        tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@)"
          "--to"
          "closest_pushable(@)"
        ];
      };
      revset-aliases = {
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
        "closest_pushable(to)" = "heads(::to & mutable() & ~description(exact:\"\") & (~empty() | merges()))";
        "desc(x)" = "description(x)";
        "pending()" = ".. ~ ::tags() ~ ::remote_bookmarks() ~ @ ~ private()";
        "private()" = "description(glob:'wip:*') | description(glob:'private:*') | description(glob:'WIP:*') | description(glob:'PRIVATE:*') | conflicts() | (empty() ~ merges()) | description('substring-i:\"DO NOT MAIL\"')";
      };
    };
  };

  programs.mergiraf = {
    enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      alias = {
        adog = "log --all --decorate --oneline --graph";
        unshallow = ''!git fetch --unshallow && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && git fetch origin'';
        patch = "push rad HEAD:refs/patches";
      };

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

    secrets.github_vcc_token = {
      path = "${config.xdg.configHome}/.github_vcc_token";
    };

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
