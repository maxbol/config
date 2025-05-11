{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.features.darwin-desktop.jankyborders;
  PATH = "/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.sketchybar}/bin:${pkgs.aerospace}/bin:${pkgs.jankyborders}/bin";
in {
  options = with lib; {
    features.darwin-desktop.jankyborders = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      pkgs.jankyborders
    ];
    services.jankyborders.enable = true;
    launchd.user.agents.jankyborders = {
      serviceConfig.ProgramArguments = lib.mkForce [
        "/bin/bash"
        "-c"
        "${pkgs.jankyborders}/bin/borders"
      ];
      environment.PATH = PATH;
    };
  };
}
