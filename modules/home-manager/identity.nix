{lib, ...}: {
  options = with lib; {
    identity = {
      userImage = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to an image representing the user";
      };
    };
  };
}
