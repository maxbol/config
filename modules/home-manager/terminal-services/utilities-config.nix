{
  pkgs,
  config,
  lib,
  self,
  ...
}: let
  cfg = config.features;
in {
  options = with lib; {
    features.terminal-services.utilities-config = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = lib.mkIf (cfg.terminal-services.utilities-config.enable) {
    home.sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "kitty";
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND = "fg=green,bold";
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND = "fg=red,bold";
    };

    # Bat
    programs.bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batgrep
        batman
      ];
    };
    programs.zsh.shellAliases = {
      cat = "${pkgs.bat}/bin/bat --paging=never";
    };

    # ZOxide
    programs.zoxide = {
      enable = true;
      enableZshIntegration = cfg.terminal-services.shell-config.enable;
      options = ["--cmd cd"];
    };

    # Skim
    programs.skim = {
      enable = true;
      enableZshIntegration = cfg.terminal-services.shell-config.enable;
      defaultCommand = "rg --files --hidden";
      changeDirWidgetOptions = [
        "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
        "--exact"
      ];
    };

    # Eza
    programs.eza.enable = true;
    programs.zsh.shellAliases = {
      l = "eza --icons";
      ll = "eza --icons -l";
      la = "eza --icons -la";
      tree = "eza --tree";
    };

    # Clockify cli
    features.terminal-services.shell-config.initExtra = [
      ''source <(${lib.getExe self.clockify-cli} completion zsh)''
    ];

    # Yazi
    programs.yazi = {
      enable = true;
      settings = {
        preview = {
          max_width = 1000;
          max_height = 1000;
        };
      };
    };

    # Misc
    home.packages = with pkgs; [
      alejandra
      bottom
      dipc
      entr
      eza
      fd
      fzf
      httpie
      jq
      lsd
      m-cli
      self.clockify-cli
      ncdu
      neofetch
      nil
      nix-info
      nnn
      nurl
      ranger
      ripgrep
      ripgrep-all
      sd
      tealdeer
      tokei
      tree
      yazi
    ];
  };
}
