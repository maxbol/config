{
  lib-mine,
  pkgs,
  lib,
  ...
}:
lib-mine.mkFeature "features.localsend" {
  programs.localsend = {
    enable = true;
    openFirewall = true;
    package = pkgs.localsend;
  };

  systemd.user.services.localsend = {
    enable = true;
    after = ["niri.service"];
    script = lib.getExe pkgs.localsend;
    wantedBy = ["niri.service"];
  };
}
