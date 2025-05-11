{lib, ...}: {
  options = with lib; {
    meta = {
      flakeRoot = mkOption {
        type = types.path;
        description = ''The path to the root of the flake'';
      };
    };
  };
}
