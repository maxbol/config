{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.gaming" {
  home.packages = with pkgs; [
    steam
    # Lutris Setup
    (lutris.override {
      extraLibraries = pkgs: [
        # List library dependencies here
        gamescope
        mangohud
      ];
      extraPkgs = pkgs: [
        # List package dependencies here
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
