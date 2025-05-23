{
  lib-mine,
  lib,
  pkgs,
  config,
  vendor,
  self,
  ...
}: let
  clockifyd = vendor.clockifyd.default;

  kube-tmux = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-tmux";
    rev = "c127fc2181722c93a389534549a217aef12db288";
    sha256 = "sha256-PnPj2942Y+K4PF+GH6A6SJC0fkWU8/VjZdLuPlEYY7A=";
  };

  usr = config.home.username;
  resurrectDirPath = "~/.tmux/resurrect/";
  ta = pkgs.writeShellScriptBin "ta" ''
    if [ "$TMUX" = "" ]; then tmux attach; fi
  '';
in
  lib-mine.mkFeature "features.tmux-config" {
    impure-config-management.config."tmux/overrides.conf" = "config/tmux/overrides.conf";

    systemd.user.services.clockifyd = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "Clockify status daemon";
        After = ["hyprland-session.target"];
      };

      Service = {
        ExecStart = "/bin/sh -c \"${pkgs.coreutils}/bin/rm -f /tmp/clockifyd.sock && ${clockifyd}/bin/clockifyd\"";
        Restart = "always";
      };

      Install.WantedBy = ["tmux.service"];
    };

    systemd.user.services.tmux = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (let
      execStartPre = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_SESSION_DESKTOP GPG_TTY XDG_CURRENT_DESKTOP TMUX_TMPDIR PATH";
      execStop = pkgs.writeShellScript "tmux-exec-stop" ''
        ${execStartPre}
        ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
      '';
    in {
      Unit = {
        Description = "tmux default session (detached)";
        Documentation = "man:tmux(1)";
        After = ["clockifyd.service"];
      };

      Service = {
        Type = "forking";
        ExecStartPre = execStartPre;
        ExecStart = "${pkgs.zsh}/bin/zsh -l -i -c \"${pkgs.tmux}/bin/tmux new-session -d\"";
        ExecStop = ["${execStop}" "${pkgs.tmux}/bin/tmux kill-server"];
        KillMode = "control-group";
        RestartSec = 2;
        Restart = "always";
        SetLoginEnvironment = true;
        Environment = ["DISPLAY=:0" "TMUX_TMPDIR=/run/user/1000/" "WAYLAND_DISPLAY=wayland-1" "XDG_SESSION_TYPE=wayland"];
      };

      Install.WantedBy = ["default.target"];
    });

    programs.tmux = {
      enable = true;
      mouse = true;
      # shell = "${pkgs.zsh}/bin/zsh";
      terminal = "screen-256color";
      historyLimit = 50000;

      resizeAmount = 30;
      baseIndex = 1;
      escapeTime = 0;

      sensibleOnTop = true;

      extraConfig =
        /*
        bash
        */
        ''
          set -gq @tinted-tmux-modulepane-right-outer "󱃾 #( KUBE_TMUX_NS_ENABLE=false KUBE_TMUX_SYMBOL_ENABLE=false ${kube-tmux}/kube.tmux )"
          set -gqa @tinted-tmux-modulepane-right-outer "  "
          set -gqa @tinted-tmux-modulepane-right-outer "󰥔 #( ${clockifyd}/bin/clockifyd-get-current )"
          set -gqF @tinted-tmux-modulepane-right-inner "%H:%M"

          source-file ${config.xdg.configHome}/tmux/overrides.conf
          source ${config.xdg.configHome}/chroma/active/tmux/tinted-tmux-statusline.conf
        '';

      plugins =
        (with pkgs; [
          # {
          #   # https://github.com/nix-community/home-manager/issues/5952
          #   plugin = tmuxPlugins.mkTmuxPlugin {
          #     pluginName = "nix-shellfix";
          #     version = "1";
          #     src = writeTextFile {
          #       name = "nix-shellfix-plugin";
          #       destination = "/nix_shellfix.tmux";
          #       executable = true;
          #       text = '''';
          #     };
          #   };
          #   extraConfig =
          #     /*
          #     bash
          #     */
          #     ''
          #       set -gu default-command
          #       set -g default-shell "$SHELL"
          #     '';
          # }
          {
            plugin = tmuxPlugins.yank;
          }
          {
            plugin = tmuxPlugins.resurrect;
            extraConfig =
              /*
              bash
              */
              ''
                set -g allow-passthrough on
                set -g @resurrect-strategy-vim 'session'
                set -g @resurrect-strategy-nvim 'session'

                set -g @resurrect-capture-pane-contents 'on'

                set -g @resurrect-dir ${resurrectDirPath}
                # set -g @resurrect-hook-post-save-all 'sed "s| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/${usr}/bin/||g; s|/home/${usr}/.nix-profile/bin/||g" ${resurrectDirPath}/last | sponge ${resurrectDirPath}/last'
                set -g @resurrect-hook-post-save-all "sed 's/--cmd[^ ]* [^ ]* [^ ]*//g; s|' $resurrect_dir/last | sponge $resurrect_dir/last"
                set -g @resurrect-processes '"~htop->htop" "~nv->nv" "~ranger->ranger" "~less->less" "~bat->bat" "~man->man" "~yazi->yazi"'
              '';
          }
          {
            plugin = tmuxPlugins.continuum;
            extraConfig =
              /*
              bash
              */
              ''
                set -g @continuum-restore 'on'
                set -g @continuum-boot 'on'
                set -g @continuum-boot-options 'kitty'
                set -g @continuum-save-interval '5'
              '';
          }
          {
            plugin = tmuxPlugins.tmux-fzf;
          }
          {
            plugin = tmuxPlugins.fzf-tmux-url;
            extraConfig =
              /*
              bash
              */
              ''
                set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
                set -g @fzf-url-history-limit '2000'
              '';
          }
          {
            plugin = tmuxPlugins.tmux-thumbs;
          }
          {
            plugin = tmuxPlugins.vim-tmux-navigator;
            extraConfig =
              /*
              bash
              */
              ''
                set -g @vim_navigator_mapping_left "C-Left C-h"  # use C-h and C-Left
                set -g @vim_navigator_mapping_right "C-Right C-l"
                set -g @vim_navigator_mapping_up "C-k"
                set -g @vim_navigator_mapping_down "C-j"
                set -g @vim_navigator_mapping_prev ""  # removes the C-\ binding
              '';
          }
          {
            plugin = tmuxPlugins.session-wizard;
            extraConfig =
              /*
              bash
              */
              ''
                set -g @session-wizard 'C-o'
              '';
          }
        ])
        ++ [
          {
            plugin = self.clockify-tmux;
          }
        ];
    };

    home.packages = [ta clockifyd];
  }
