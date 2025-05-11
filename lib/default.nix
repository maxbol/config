{lib, ...}: rec {
  barrelGroup = (import ./barrel-group.nix) {inherit lib;};
  batchEnable = path: submodules: let
    pathComponents = lib.traceVal (lib.path.subpath.components path);
    ret = lib.attrsets.setAttrByPath pathComponents (builtins.listToAttrs (map (submodule: {
        name = submodule;
        value = {
          enable = true;
        };
      })
      submodules));
  in
    ret;

  barrelSubmoduleImports = {
    here,
    path,
    submodules,
  }:
    map (
      submodule: {
        config,
        lib,
        ...
      }: let
        pathComponents = lib.path.subpath.components path;
        enablePath = pathComponents ++ ["enable"];
        submodulePath = pathComponents ++ [submodule];
      in {
        config =
          lib.mkIf
          (lib.attrByPath enablePath false config)
          (
            lib.attrsets.setAttrByPath
            submodulePath
            {enable = true;}
          );
        imports = [(here + "/${submodule}.nix")];
      }
    )
    submodules;
}
