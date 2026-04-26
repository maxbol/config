{
  lib-mine,
  lib,
  origin,
  pkgs,
  vendor,
  self,
  ...
}: let
  nixpkgs-unstable = import origin.inputs.nixpkgs-unstable {
    system = pkgs.system;
  };

  withGoRootWrapper = pkg: binName:
    pkgs.writeShellScriptBin binName ''
      export GOROOT=${pkgs.go}
      ${lib.getExe pkg} $*
    '';

  # Wrap sqlcmd to make output legible in dadbod
  sqlcmd = pkgs.writeShellScriptBin "sqlcmd" ''
    ${pkgs.sqlcmd}/bin/sqlcmd -w 200 -Y 36 "$@"
  '';

  swag = withGoRootWrapper pkgs.go-swag "swag";

  # Non-nixpkgs packages
  nancy = self.nancy;
  synp = self.synp;
  zig = vendor.zig-overlay.default;
  zls = vendor.zls.default;

  ccjson = pkgs.writeShellScriptBin "ccjson" ''
    make --always-make --dry-run \
     | grep -wE 'clang|gcc|g\+\+' \
     | grep -w '\-c' \
     | jq -nR '[inputs|{directory:".", command:., file: match(" [^ ]+$").string[1:]}]' \
     > compile_commands.json
  '';
in
  lib-mine.mkFeature "features.default-development-environment" {
    home.packages =
      (with pkgs; [
        # NodeJS
        nodejs_22
        yarn
        yarn2nix
        vscode-langservers-extracted
        nodePackages.fixjson
        # nodePackages.ts-node
        asdf
        asdf-vm
        nixpkgs-unstable.deno
        pnpm

        # Golang
        nixpkgs-unstable.go
        nixpkgs-unstable.gopls
        nixpkgs-unstable.golangci-lint
        nixpkgs-unstable.golangci-lint-langserver
        nixpkgs-unstable.gotools
        nixpkgs-unstable.delve

        # Protobuffers
        buf

        # Rust
        cargo
        rust-analyzer

        # Odin
        odin
        ols

        # C/C++
        man-pages
        man-pages-posix
        gcc
        gnumake
        checkmake
        llvm
        lldb
        tracy
        bear
        meson
        ninja
        cmake
        # clang

        # Vala
        vala

        # Godot
        godot

        #OCaml
        ocaml
        dune_3
        ocamlPackages.ocaml-lsp
        ocamlPackages.earlybird
        ocamlPackages.ocamlformat

        # Swift
        # sourcekit-lsp

        # CSharp
        dotnet-sdk_9
        omnisharp-roslyn
        csharpier
        netcoredbg
        roslyn-ls

        # Nix
        alejandra
        nixd

        # Lua
        stylua
        lua-language-server
        lua5_1
        luau
        luarocks

        # Gleam
        gleam

        # GLSL
        glsl_analyzer
        shaderc

        # Python
        # (python3.withPackages
        #   (ps: [
        #     ps.pyyaml
        #     ps.pip
        #   ]))
        # pipx

        # Docker
        hadolint
        dockerfile-language-server-nodejs
        docker-compose-language-service
        grype

        # Version management tooling
        lazygit
        gh

        # Package management, virtualisation, environments, etc
        # origin.inputs.devenv.packages.${pkg.system}.devenv
        devenv

        # Global libs/tooling
        openssl
        silicon
        mdcat
        hurl

        # Shell scripting
        nushell
        nufmt

        # Low level tools
        lsof
        # netcat-openbsd
        # procps

        # QMK keyboard firmware
        qmk
      ])
      ++ [
        # Wrappers, custom and non-nixpkgs packages
        ccjson
        nancy
        sqlcmd
        swag
        synp
        zig
        zls
      ]
      ++ (
        lib.optionals (pkgs.stdenv.hostPlatform.isLinux) [pkgs.gdb]
      );
  }
