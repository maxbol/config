# Offline instruction-set reference, used by the assembly viewer in neovim
# (config/nvim/lua/neomax/configs/asm). `gm` in the assembly pane resolves the
# instruction under the cursor to one of these pages.
#
# Not in nixpkgs, so it is built here: the upstream repo is just a directory of
# pre-generated section 7 pages, produced from Intel's SDM via Félix Cloutier's
# HTML conversion.
{pkgs, ...}: let
  x86-manpages = pkgs.stdenvNoCC.mkDerivation {
    pname = "x86-manpages";
    version = "0-unstable-2020-03-10";

    src = pkgs.fetchFromGitHub {
      owner = "ttmo-O";
      repo = "x86-manpages";
      rev = "94902f9c45de0efe803c32b6c3e88d6623881866";
      hash = "sha256-wpQC41/H5gAla8aVUGzX+dtEPnh+Cu6jhJbjv5TT1kw=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/man/man7"
      cp man7/*.7 "$out/share/man/man7/"
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Manual pages for the x86 and x86-64 instruction set";
      homepage = "https://github.com/ttmo-O/x86-manpages";
      license = licenses.free; # derived from Intel documentation
      platforms = platforms.all; # reference text, useful on any host
    };
  };
in {
  home.packages = [x86-manpages];
}
