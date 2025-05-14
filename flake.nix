{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-cli = {
      url = "github:peterldowns/nix-search-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nur.url = "github:nix-community/NUR";
    textfox.url = "github:maxbol/textfox/copy-on-activation-mode@allow-custom-css@flatten-css";

    zig-overlay.url = "github:mitchellh/zig-overlay";

    clockifyd.url = "github:maxbol/clockifyd";
    nvim-colorctl.url = "github:maxbol/nvim-colorctl/log-the-shit-out-of-the-filenotfound-error";
    obsidian-remote.url = "github:maxbol/obsidian-remote";
  };

  outputs = inputs @ {
    nix-darwin,
    home-manager,
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } (
      {
        config,
        options,
        self,
        ...
      } @ flake-args: let
        hmModuleRoot = import ./modules/home-manager;
        themeConfigModule = import ./modules/home-manager/theme-config;
        darwinModuleRoot = import ./modules/darwin;
        overlays = (import ./overlays) flake-args;
        lib-mine = (import ./lib) {inherit (nixpkgs) lib;};
        moduleArgs = self // {inherit config options;};
        systems = [
          "aarch64-darwin"
          "x86_64-linux"
        ];
      in {
        inherit systems;

        debug = true;

        imports = [
          ./meta.nix
          (import ./transpose-themes.nix {inherit flake-parts self;})
        ];

        perSystem = {
          pkgs,
          self',
          system,
          ...
        } @ perSystemArgs: let
          packageArgs = {
            self = self'.packages;
            inputs = inputs;
          };
        in {
          _module.args.pkgs = import nixpkgs {
            inherit system overlays;
          };

          packages = pkgs.callPackage ./packages packageArgs;
          themes = import ./themes (perSystemArgs // packageArgs);
        };

        flake = let
          mkPackages = system:
            import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
            };

          mkSpecialArgs = system: let
            pkgs = mkPackages system;
          in {
            inherit lib-mine;
            origin = moduleArgs;
            self = self.packages.${system};
            vendor = pkgs.lib.foldlAttrs (inputPackages: inputName: input:
              inputPackages
              // (
                if inputName == "nixpkgs"
                then {}
                else {${inputName} = input.packages.${system};}
              )) {}
            inputs;
          };

          mkDarwinConfiguration = {host}: let
            hostModule = import (./. + ''/hosts/darwin/${host}'');
          in
            nix-darwin.lib.darwinSystem {
              specialArgs = mkSpecialArgs "aarch64-darwin";
              pkgs = mkPackages "aarch64-darwin";
              modules = [
                darwinModuleRoot
                hostModule
              ];
            };

          mkHomeManagerConfiguration = {
            system,
            username,
            host,
          }: let
            userModule = import (./. + ''/users/${username}@${host}'');
          in
            home-manager.lib.homeManagerConfiguration {
              modules = [
                hmModuleRoot
                userModule
              ];
              pkgs = mkPackages system;
              extraSpecialArgs = mkSpecialArgs system;
            };
        in {
          darwinConfigurations."void" = mkDarwinConfiguration {host = "void";};
          homeConfigurations."maxbolotin@void" = mkHomeManagerConfiguration {
            system = "aarch64-darwin";
            username = "maxbolotin";
            host = "void";
          };

          darwinModules = {
            all = darwinModuleRoot;
          };

          homeManagerModules = {
            all = hmModuleRoot;
            themeConfig = themeConfigModule;
          };
        };

        meta = {
          flakeRoot = ./.;
        };
      }
    );
}
