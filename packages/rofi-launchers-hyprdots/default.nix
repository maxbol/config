{
  symlinkJoin,
  writeShellApplication,
  bc,
  gnused,
  gawk,
  rofi-wayland,
  dunst,
  dconf,
  cliphist,
  self,
  # inputs,
  lib,
  hyprland,
  ...
}: let
  runtimeInputs = [
    hyprland
    # inputs.hyprland.packages.default
    gnused
    gawk
    rofi-wayland
    dunst
    dconf
    bc
    cliphist
    self.chromactl
    self.nailgun
  ];

  lib_compositor = writeShellApplication {
    name = "compositor.sh";
    inherit runtimeInputs;
    checkPhase = "";
    text = builtins.readFile ./lib/compositor.sh;
  };
in
  symlinkJoin {
    name = "rofi-launcher-hyprdots";
    paths = builtins.map (f:
      writeShellApplication {
        name = f;
        runtimeInputs = runtimeInputs ++ [lib_compositor];
        checkPhase = "";
        text = builtins.readFile "${./src}/${f}";

        meta = with lib; {
          description = "A launcher for Rofi from Hyprdots.";
          homepage = "https://github.com/prasanthrangan/hyprdots";
          license = licenses.gpl3Only;
          maintainers = ["Cu3PO42"];
          platforms = platforms.linux;
        };
      }) (builtins.attrNames (builtins.readDir ./src));
  }
