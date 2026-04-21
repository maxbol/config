{
  lib-mine,
  pkgs,
  vendor,
  origin,
  ...
}: let
  fff-nvim = origin.inputs.fff.packages.${pkgs.system}.fff-nvim;

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

  vscode-lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;

  vscode-lldb-neovim = pkgs.symlinkJoin {
    name = "vscode-lldb-neovim";
    paths = [
      vscode-lldb
      (
        pkgs.runCommand "vscode-lldb-bin" {} ''
          mkdir -p $out/bin
          ln -s ${vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $out/bin/codelldb
        ''
      )
    ];
  };

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
    lldb_20
    mesonlsp
    prettierd
    shfmt
    sql-formatter
    sqlfluff
    typescript-language-server
    vala-language-server
    vscode-lldb-neovim
    vtsls
    tinymist
    typstyle
    websocat
    cargo
    rustc
    rust-analyzer
    rustfmt
    shellcheck

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

    home.file.".local/share/nvim/fff-nvim-plugin" = {
      source = fff-nvim;
    };

    impure-config-management.config."nvim" = "config/nvim";
  }
