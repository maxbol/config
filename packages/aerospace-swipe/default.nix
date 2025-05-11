{pkgs, ...}: let
  pname = "aerosopace-swipe";
  version = "git";
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;
    src = pkgs.fetchFromGitHub {
      owner = "acsandmann";
      repo = "aerospace-swipe";
      rev = "f5abb13ccb665bbb66ee704566d7d3c069e0e92e";
      hash = "sha256-mwpK7w+VCy0ilV+hDwa7rsve/Om3yEy8E9bRHFLVvro=";
    };

    buildInputs = with pkgs; [
      apple-sdk_15
    ];

    buildPhase = ''
      mkdir -p plist
      make LAUNCH_AGENTS_DIR=./plist all bundle install_plist
    '';

    installPhase = ''
      mkdir -p $out/{Applications,share/plist}
      cp AerospaceSwipe.app $out/Applications
      cp plist/com.acsandmann.swipe.plist $out/share/plist
    '';
  }
