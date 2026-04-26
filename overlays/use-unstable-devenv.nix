# https://github.com/NixOS/nixpkgs/issues/420134
{inputs, ...}: _: prev: let
  devenv = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.devenv;
in {
  inherit devenv;
}
