{
  pkgs,
  procps,
  envsubst,
  dconf,
  lib,
  writeShellApplication,
  jq,
  bc,
  gnused,
  ...
}: let
  runtimeInputs = [
    procps
    envsubst
    dconf
    jq
    bc
    gnused
  ];

  compositorLib = writeShellApplication {
    name = "compositor.sh";
    inherit runtimeInputs;
    checkPhase = "";
    text = builtins.readFile ./lib/compositor.sh;
  };
in
  pkgs.writeShellApplication {
    name = "wlogout-launcher-hyprland";
    runtimeInputs = runtimeInputs ++ [compositorLib];
    checkPhase = "";
    text = builtins.readFile ./wlogout-launcher-hyprdots.sh;

    meta = with lib; {
      description = "The tool to start wlogout from Hyprdots.";
      homepage = "https://github.com/prasanthrangan/hyprdots";
      license = licenses.gpl3Only;
      maintainers = ["Cu3PO42"];
      platforms = platforms.linux;
    };
  }
