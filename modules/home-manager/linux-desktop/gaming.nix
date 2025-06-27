{
  lib-mine,
  self,
  pkgs,
  ...
}: let
in
  lib-mine.mkFeature "features.linux-desktop.gaming" {
    home.packages = with pkgs; [
      steam
      heroic
      # Lutris Setup
      (lutris.override {
        extraLibraries = pkgs: [
          gamescope
          mangohud
          self.openssl_1_0 # Needed for some native linux games
        ];
        extraPkgs = pkgs: [
          wineWowPackages.stableFull
          libgudev
          libvdpau
          libsoup
          libusb1
          gamescope
          mangohud
        ];
      })
      vulkan-tools
    ];
    home.sessionVariables = {
      MESA_GL_VERSION_OVERRIDE = "4.5";
    };
  }
