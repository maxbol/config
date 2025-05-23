{
  lib,
  config,
  ...
}: let
  cfg = config.identity;
in {
  options = with lib; {
    identity = {
      userImage = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to an image representing the user";
      };
    };
  };

  config = lib.mkIf (cfg.userImage != null) {
    home.file.".face.icon" = {
      source = cfg.userImage;
    };
  };
}
