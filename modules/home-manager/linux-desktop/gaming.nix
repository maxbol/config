{
  lib-mine,
  self,
  pkgs,
  ...
}: let
in
  lib-mine.mkFeature "features.linux-desktop.gaming" (let
    # gamescope-patched = pkgs.gamescope.overrideAttrs {
    #   src = pkgs.fetchFromGitHub {
    #     owner = "zlice";
    #     repo = "gamescope";
    #     rev = "fa900b0694ffc8b835b91ef47a96ed90ac94823b";
    #     fetchSubmodules = true;
    #     hash = "sha256-8KT/YEDFOyUiCAqPxuCc0SzJuwquyo/mxYMx0LBiyHM=";
    #   };
    # };
    # gamescope = self.gamescope-reaperpatch;
    gamescope = pkgs.gamescope;

    extraPkgs = _:
      with pkgs; [
        wineWowPackages.stableFull
        libgudev
        libvdpau
        # TODO: Check if lutris/heroic still works with libsoup 3, otherwise we have to allow libsoup 2 as an insecure package
        # libsoup_2_4
        libsoup_3
        libusb1
        gamescope
        mangohud
        winetricks
        protontricks
      ];
    extraLibraries = _:
      with pkgs; [
        gamescope
        mangohud
        self.openssl_1_0 # Needed for some native linux games
      ];
  in {
    home.packages = let
    in
      with pkgs; [
        # Heroic setup
        (heroic.override {
          inherit extraLibraries extraPkgs;
        })
        # Lutris Setup
        (lutris.override {
          inherit extraLibraries extraPkgs;
        })
        # Steam setup
        (
          steam.override (prev: {
            extraEnv = {};
            extraLibraries = pkgs:
              (
                extraLibraries pkgs
              )
              ++ (
                if prev ? extraLibraries
                then (prev.extraLibraries pkgs)
                else []
              );
          })
        )
        vulkan-tools
      ];
    home.sessionVariables = {
      MESA_GL_VERSION_OVERRIDE = "4.5";
    };
  })
