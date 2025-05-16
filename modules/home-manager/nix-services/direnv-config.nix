{
  lib,
  lib-mine,
  pkgs,
  ...
}: let
  tmpDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/private/tmp/"
    else "/run/user/";
in
  lib-mine.mkFeature "features.nix-services.direnv-config" (lib.mkMerge [
    {
      programs.direnv.enable = true;
      programs.direnv.enableZshIntegration = true;
      programs.direnv.nix-direnv.enable = true;

      xdg.configFile."direnv/direnvrc" = {
        text = ''
          : ''${DIRENV_DIR:=${tmpDir}$UID}
          declare -A direnv_layout_dirs
          direnv_layout_dir() {
          local hash path
          echo "''${direnv_layout_dirs[$PWD]:=$(
              hash="$(${pkgs.coreutils}/bin/sha1sum - <<< "$PWD" | head -c40)"
              path="''${PWD//[^a-zA-Z0-9]/-}"
              echo "''${DIRENV_DIR}/direnv/''${hash}''${path}"
              )}"
          }
        '';
      };

      home.sessionVariables.DIRENV_LOG_FORMAT = "";
      launchd.agents.clearDirenv = {
        enable = true;
        config = {
          Program = "/bin/bash";
          ProgramArguments = ["-c" ''rm -rf ${tmpDir}''${UID}/direnv/*''];
          RunAtLoad = true;
        };
      };
    }
  ])
