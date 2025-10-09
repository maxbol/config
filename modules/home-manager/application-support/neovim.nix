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

  extraPackages = with pkgs; [
    origin.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.tree-sitter
    imagemagick
    fd
    ripgrep
    luajit
    luajitPackages.tiktoken_core

    # Language tooling - migration from Mason
    clang-tools
    deno
    eslint
    eslint_d
    html-tidy
    mesonlsp
    prettierd
    shfmt
    sql-formatter
    sqlfluff
    typescript-language-server
    vala-language-server

    ocamlPackages.ocaml-lsp
    ocamlPackages.earlybird
    ocamlPackages.ocamlformat
  ];
  extraLuaPackages = ps: [ps.magick];
in
  lib-mine.mkFeature "features.application-support.neovim" {
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    programs.neovim = {
      enable = true;
      package = neovim-unwrapped;
      inherit extraPackages extraLuaPackages;
    };

    programs.zsh.shellAliases = {
      nv = "nvim";
    };

    home.packages = with pkgs; [
      neovim-remote
      nvim-colorctl
      neovide
    ];

    impure-config-management.config."nvim" = "config/nvim";
  }
