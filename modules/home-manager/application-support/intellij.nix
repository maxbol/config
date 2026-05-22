{
  origin,
  lib-mine,
  pkgs,
  ...
}: let
  nixpkgs-unstable = import origin.inputs.nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
in
  lib-mine.mkFeature "features.application-support.intellij" (let
    fixScaling = xcursorsize: xcursortheme: pkg: mainProgram:
      pkg.overrideAttrs (prevAttrs: {
        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [pkgs.makeWrapper];
        postInstall =
          (prevAttrs.postInstall or "")
          + ''
            wrapProgram $out/bin/${mainProgram} --set XCURSOR_SIZE ${toString xcursorsize} --set XCURSOR_THEME ${xcursortheme}
          '';
      });

    datagrip = fixScaling 28 "macOS" nixpkgs-unstable.jetbrains.datagrip "datagrip"; # Use unstable to get access to 2026.1.1 wayland support
  in {
    home.packages = [
      datagrip
    ];

    home.file.".ideavimrc" = {
      text = ''
        set clipboard+=unnamed
      '';
    };
  })
