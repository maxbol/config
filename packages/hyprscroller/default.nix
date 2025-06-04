{
  lib,
  hyprland,
  cmake,
  fetchFromGitHub,
  unstableGitUpdater,
  stdenv,
  pkg-config,
  ...
}: let
  mkHyprlandPlugin = hyprland: args @ {pluginName, ...}:
    stdenv.mkDerivation (
      args
      // {
        pname = "${pluginName}";
        nativeBuildInputs = [pkg-config] ++ args.nativeBuildInputs or [];
        buildInputs = [hyprland] ++ hyprland.buildInputs ++ (args.buildInputs or []);
        meta =
          args.meta
          // {
            description = args.meta.description or "";
            longDescription =
              (args.meta.longDescription or "")
              + "\n\nPlugins can be installed via a plugin entry in the Hyprland NixOS or Home Manager options.";
          };
      }
    );
in
  mkHyprlandPlugin hyprland {
    pluginName = "hyprscroller";
    version = "0-unstable-2024-11-23";

    src = fetchFromGitHub {
      owner = "dawsers";
      repo = "hyprscroller";
      rev = "7e63677d2cfa5722870fef10377d0a5d3de02db6";
      hash = "sha256-+lwcWkUyqm3tKOPy1hjPDZG+pPIw6io4YBNeL8ThjV8=";
    };

    nativeBuildInputs = [cmake];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      mv hyprscroller.so $out/lib/libhyprscroller.so

      runHook postInstall
    '';

    passthru.updateScript = unstableGitUpdater {};

    meta = {
      homepage = "https://github.com/dawsers/hyprscroller";
      description = "Hyprland layout plugin providing a scrolling layout like PaperWM";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [donovanglover];
      platforms = lib.platforms.linux;
    };
  }
