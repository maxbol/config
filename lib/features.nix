{lib, ...}: rec {
  batchEnable = let
    enable = name: {${name}.enable = true;};
  in {};
  barrelGroup = {
    path,
    here,
    submodules,
  }: let
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
            value = {enable = lib.mkDefault true;};
          })
          submodules)
      );
    };

  mkFeature = path: module: let
    pathComponents = lib.strings.splitString "." path;
  in {
    imports = [
      ({config, ...} @ moduleArgs: let
        cfg = lib.attrByPath pathComponents {enable = false;} config;

        resolvedModule =
          if builtins.isFunction module
          then (module moduleArgs)
          else module;

        moduleConfig =
          if resolvedModule ? config
          then resolvedModule.config
          else resolvedModule;

        resolvedModuleConfig =
          if builtins.isFunction moduleConfig
          then (moduleConfig cfg)
          else moduleConfig;

        moduleOpts =
          if resolvedModule ? options
          then resolvedModule.options
          else {};

        moduleImports =
          if resolvedModule ? imports
          then resolvedModule.imports
          else [];
      in {
        options = lib.attrsets.setAttrByPath pathComponents ({
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          }
          // moduleOpts);

        config = lib.mkIf cfg.enable resolvedModuleConfig;

        imports = moduleImports;
      })
    ];
  };
}
