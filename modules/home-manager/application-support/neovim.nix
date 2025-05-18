{
  lib-mine,
  pkgs,
  vendor,
  origin,
  ...
}: let
  neovim-unwrapped = vendor.neovim-nightly-overlay.default.overrideAttrs (old: {
    meta =
      old.meta
      or {}
      // {
        maintainers = old.maintainers or [];
      };
    treesitter-parsers = {};
  });

  nvim-colorctl = vendor.nvim-colorctl.default;
in
  lib-mine.mkFeature "features.application-support.neovim" {
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    programs.neovim = {
      enable = true;
      package = neovim-unwrapped;
      extraPackages = with pkgs; [
        origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.tree-sitter
        imagemagick
        fd
        ripgrep
        luajit
        luajitPackages.tiktoken_core
      ];
      extraLuaPackages = ps: [ps.magick];
    };

    programs.zsh.shellAliases = {
      nv = "nvim";
    };

    home.packages = with pkgs; [
      neovim-remote
      nvim-colorctl
    ];

    impure-config-management.config."nvim" = "config/nvim";
  }
