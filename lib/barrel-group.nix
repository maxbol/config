{lib}: ({
  path,
  here,
  submodules,
  config,
}: let
  pathComponents = lib.strings.splitString "." path;
  cfg = lib.attrByPath pathComponents {enable = false;} config;
in {
  options = lib.attrsets.setAttrByPath pathComponents {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = map (name: here + "/${name}.nix") submodules;

  config = lib.mkIf cfg.enable (
    lib.attrsets.setAttrByPath pathComponents (
      builtins.listToAttrs (map (name: {
          name = name;
          value = {enable = true;};
        })
        submodules)
    )
  );
})
