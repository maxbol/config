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

  # devenv 2's `direnv-export` reads stdin while it evaluates, swallowing
  # keystrokes queued in the pane while the direnv hook runs — i.e. the pane
  # commands workmux types at window creation. Scope the stdin detach to that
  # window only: fresh shells (DIRENV_DIR unset) inside workmux sessions
  # (window_prefix, default wm-). There the progress UI degrades to a plain
  # log; every other activation passes through with the animated TUI.
  devenvDirenvSafe = pkgs.writeShellScriptBin "devenv-direnv-safe" ''
    if [[ -n ''${TMUX_PANE:-} && -z ''${DIRENV_DIR:-} ]] \
        && tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null | grep -q '^wm-'; then
      exec "$(command -v devenv)" "$@" </dev/null
    fi
    exec "$(command -v devenv)" "$@"
  '';
in
  lib-mine.mkFeature "features.nix-services.direnv-config" (lib.mkMerge [
    {
      programs.direnv.enable = true;
      programs.direnv.enableZshIntegration = true;
      programs.direnv.enableNushellIntegration = true;
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

          # devenv's direnvrc honors DEVENV_BIN; route it through the safe wrapper.
          if [[ -z ''${DEVENV_BIN:-} ]] && command -v devenv >/dev/null; then
              DEVENV_BIN="${devenvDirenvSafe}/bin/devenv-direnv-safe"
          fi
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

      systemd.user.services.clear-direnv = {
        Unit = {
          Description = "clear direnv roots";
          Before = ["default.target"];
        };

        Service = {
          Type = "oneshot";
          Restart = "no";
          ExecStart = ''/bin/sh -c "${pkgs.coreutils}/bin/rm -rf %t/direnv/*"'';
        };

        Install.WantedBy = ["default.target"];
      };
    }
  ])
