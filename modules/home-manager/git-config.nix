{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features;
in {
  options = with lib; {
    features.git-config = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf (cfg.git-config.enable) {
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
  };
}
