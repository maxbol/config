{
  lib-mine,
  self,
  pkgs,
  ...
}: let
in
  lib-mine.mkFeature "features.linux-desktop.gaming" (let
    extraPkgs = _:
      with pkgs; [
        wineWowPackages.stableFull
        libgudev
        libvdpau
        libsoup
        libusb1
        gamescope
        mangohud
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
