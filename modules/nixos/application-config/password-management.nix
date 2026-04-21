{
  lib-mine,
  lib,
  # origin,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.application-config.password-management" ({config, ...}: let
  # unstable-pkgs = import origin.inputs.nixpkgs-unstable {
  #   system = pkgs.system;
  #   config = {
  #     allowUnfree = true;
  #   };
  # };
  # beta = with unstable-pkgs;
  #   _1password-gui-beta.overrideAttrs {
  #     preFixup = ''
  #       makeShellWrapper $out/share/1password/1password $out/bin/1password \
  #         "''${gappsWrapperArgs[@]}" \
  #         --suffix PATH : ${lib.makeBinPath [xdg-utils]} \
  #         --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [udev]} \
  #         --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  #     '';
  #   };
in {
  programs._1password.enable = true;
  programs._1password-gui = {
    # package = beta;
    enable = true;
    polkitPolicyOwners = lib.attrNames config.users.users;
  };
  environment.variables = {
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.bitwarden-cli
  ];
})
