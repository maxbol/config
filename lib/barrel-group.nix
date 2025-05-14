{lib, ...} @ args: {
  path,
  here,
  submodules,
}: let
  mkFeature = (import ./mk-feature.nix) args;
  pathComponents = lib.strings.splitString "." path;
  submodulesToImports = map (name: (let
    p = here + "/${name}";
  in
    if builtins.pathExists p
    then p
    else (p + ".nix")));
in
  mkFeature path {
    imports = submodulesToImports submodules;
    config = lib.attrsets.setAttrByPath pathComponents (
      builtins.listToAttrs (map (name: {
          name = name;
          value = {enable = true;};
        })
        submodules)
    );
  }
