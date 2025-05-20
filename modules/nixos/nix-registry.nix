{
  origin,
  lib,
  lib-mine,
  ...
}: let
  inputsToRegistry = lib.attrsets.mapAttrs (_: input: {
    flake = input;
  });
in
  lib-mine.mkFeature "features.nix-registry" {
    nix.registry = inputsToRegistry origin.inputs;
  }
