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

    nur.url = "github:nix-community/NUR";
    textfox.url = "github:maxbol/textfox/copy-on-activation-mode@allow-custom-css@flatten-css";

    flake-parts.url = "github:hercules-ci/flake-parts";
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
        darwinModuleRoot = import ./modules/darwin;
        overlays = (import ./overlays) flake-args;
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
          ({lib, ...}: (
            flake-parts.lib.mkTransposedPerSystemModule {
              name = "themes";
              file = ./flake.nix;
              option = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = ''
                  A set of themes for the themeing system to use.
                '';
              };
            }
          ))
        ];

        perSystem = {
          pkgs,
          self',
          system,
          ...
        }: let
          packageArgs = {
            self = self'.packages;
            inputs = inputs;
          };
        in {
          _module.args.pkgs = import nixpkgs {
            inherit system overlays;
          };

          packages = pkgs.callPackage ./packages packageArgs;
          themes = pkgs.callPackage ./themes packageArgs;
        };

        flake = let
          mkLib = pkgs: ((import ./lib) {inherit (pkgs) lib;});
          mkPackages = system:
            import nixpkgs {
              inherit system overlays;
            };

          mkSpecialArgs = system: let
            pkgs = mkPackages system;
          in {
            origin = moduleArgs;
            self = self.packages.${system};
            lib-mine = mkLib pkgs;
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
        };

        meta = {
          flakeRoot = ./.;
        };
      }
    );
}
