{pkgs, ...}: let
  src = pkgs.fetchFromGitHub {
    owner = "Jas-SinghFSU";
    repo = "HyprPanel";
    rev = "c203ffe80f4e7b68e22ba3fde0598622500f5add";
    hash = "sha256-kx7hCuML0sMcjbyjbpplNWsJjLoUfiy23JiS9aG4UWw=";
  };
in
  pkgs.runCommand "hyprpanel-themes" {} ''
    mkdir -p $out/share/themes
    cp -R ${src}/themes/* $out/share/themes
  ''
