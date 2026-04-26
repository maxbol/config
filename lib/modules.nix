{lib, ...}: rec {
  injectArgs = args: f: let
    fArgs = lib.functionArgs f;
    remainingArgs = builtins.removeAttrs fArgs (builtins.attrNames args);
    requiredExtraArgs = builtins.intersectAttrs fArgs args;
    newFun = opts: f (opts // requiredExtraArgs);
  in
    lib.setFunctionArgs newFun remainingArgs;

  injectArgsOpt = args: module:
    if lib.isFunction module
    then injectArgs args module
    else module;

  importInjectArgs = args: path: lib.setDefaultModuleLocation path (injectArgsOpt args (import path));
}
