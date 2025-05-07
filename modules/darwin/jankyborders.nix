{
  pkgs,
  lib,
  ...
}: let
  PATH = "/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.sketchybar}/bin:${pkgs.aerospace}/bin:${pkgs.jankyborders}/bin";
in {
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
}
