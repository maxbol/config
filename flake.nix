{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = {
    self,
    nix-darwin,
    home-manager,
    flake-utils,
    nixpkgs,
  }: let
    voidHostConfig = import ./hosts/darwin/void;
  in (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      allowUnfree = true;
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."void" = nix-darwin.lib.darwinSystem {
      modules = [voidHostConfig];
      specialArgs = {
        inherit self;
      };
      inherit pkgs;
    };

    # homeConfigurations."maxbolotin@void" = home-manager.lib.homeConfiguration {
    #   inherit pkgs;
    # };
  }));
}
