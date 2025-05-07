{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    home-manager,
    flake-parts,
    nixpkgs,
  }: let
    voidHostConfig = import ./hosts/darwin/void;
    maxbolotinAtVoidHostConfig = import (./. + "/users/maxbolotin@void/default.nix");

    overlays = [
      (final: prev: {
        nodejs = prev.nodejs_22;
        nodejs-slim = prev.nodejs-slim_22;
        nodejs_20 = prev.nodejs_22;
        nodejs-slim_20 = prev.nodejs-slim_22;
      })
    ];
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
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
        darwinPackages = import nixpkgs {
          system = "aarch64-darwin";
          inherit overlays;
        };

        specialArgs = {
          origin = self;
        };
      in {
        darwinConfigurations."void" = nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          pkgs = darwinPackages;
          modules = [
            voidHostConfig
          ];
        };

        homeConfigurations."maxbolotin@void" = home-manager.lib.homeManagerConfiguration {
          modules = [
            maxbolotinAtVoidHostConfig
          ];
          pkgs = darwinPackages;
          extraSpecialArgs = specialArgs;
        };
      };
    };
}
