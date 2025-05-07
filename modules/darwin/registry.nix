{
  origin,
  lib,
  ...
}: let
  inputsToRegistry = lib.attrsets.mapAttrs (_: input: {
    flake = input;
  });
in {
  nix.registry = inputsToRegistry origin.inputs;
}
