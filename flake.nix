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

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # The Window Manager I use + tooling
    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.systems.follows = "systems-linux";
      # inputs.hyprutils.follows = "hyprutils";
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprlang";
      # inputs.systems.follows = "systems-linux";
    };

    custom-udev-rules.url = "github:MalteT/custom-udev-rules";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nur.url = "github:nix-community/NUR";
    textfox.url = "github:maxbol/textfox/copy-on-activation-mode@allow-custom-css@flatten-css";

    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";

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
        nixosModuleRoot = import ./modules/nixos;
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
          # (import ./transpose-themes.nix {inherit flake-parts self lib-mine;})
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
            vendor = pkgs.lib.foldlAttrs (inputPackages: inputName: input:
              inputPackages
              // (
                if inputName == "nixpkgs"
                then {}
                else {${inputName} = input.packages.${system};}
              )) {}
            inputs;
          };
        in {
          _module.args.pkgs = import nixpkgs {
            inherit system overlays;
          };

          packages = pkgs.callPackage ./packages packageArgs;
          # themes = import ./themes (
          #   {
          #     inherit pkgs lib lib-mine options;
          #   }
          #   // packageArgs
          # );
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

          mkDarwinConfiguration = {
            host,
            system,
          }: let
            hostModule = import (./. + ''/hosts/darwin/${host}'');
          in
            nix-darwin.lib.darwinSystem {
              specialArgs = mkSpecialArgs system;
              pkgs = mkPackages system;
              modules = [
                darwinModuleRoot
                hostModule
                ({lib, ...}: {
                  nixpkgs.hostPlatform = lib.mkDefault system;
                })
              ];
            };

          mkDarwinConfigurations = builtins.foldl' (acc: config @ {host, ...}:
            acc
            // {
              ${host} = mkDarwinConfiguration config;
            }) {};

          mkNixosConfiguration = {
            host,
            system,
          }: let
            hostModule = import (./. + "/hosts/nixos/${host}");
          in
            nixpkgs.lib.nixosSystem {
              specialArgs = mkSpecialArgs system;
              pkgs = mkPackages system;
              modules = [
                nixosModuleRoot
                hostModule
                ({lib, ...}: {
                  nixpkgs.hostPlatform = lib.mkDefault system;
                })
              ];
            };

          mkNixosConfigurations = builtins.foldl' (acc: config @ {host, ...}:
            acc
            // {
              ${host} = mkNixosConfiguration config;
            }) {};

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
                ({lib, ...}: {
                  home.username = username;
                  home.homeDirectory =
                    lib.mkDefault
                    (
                      if system == "aarch64-darwin"
                      then "/Users/${username}/"
                      else "/home/${username}"
                    );
                })
              ];
              pkgs = mkPackages system;
              extraSpecialArgs = mkSpecialArgs system;
            };

          mkHomeManagerConfigurations = builtins.foldl' (acc: config @ {
            username,
            host,
            ...
          }:
            acc
            // {
              "${username}@${host}" = mkHomeManagerConfiguration config;
            }) {};
        in {
          nixosConfigurations = mkNixosConfigurations [
            {
              host = "jockey";
              system = "x86_64-linux";
            }
            {
              host = "frugal";
              system = "x86_64-linux";
            }
          ];

          darwinConfigurations = mkDarwinConfigurations [
            {
              host = "void";
              system = "aarch64-darwin";
            }
          ];

          homeConfigurations = mkHomeManagerConfigurations [
            {
              system = "aarch64-darwin";
              username = "maxbolotin";
              host = "void";
            }
            {
              system = "x86_64-linux";
              username = "max";
              host = "frugal";
            }
          ];

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

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
