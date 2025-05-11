{
  config,
  origin,
  lib,
  ...
}: let
  cfg = config.features.nix-registry;
  inputsToRegistry = lib.attrsets.mapAttrs (_: input: {
    flake = input;
  });
in {
  options = with lib; {
    features.nix-registry = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    nix.registry = inputsToRegistry origin.inputs;
  };
}
