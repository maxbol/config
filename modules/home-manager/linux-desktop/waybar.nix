{
  config,
  lib-mine,
  lib,
  self,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.waybar" {
  systemd.user.services.waybar = let
    confgen = "${lib.getExe self.waybar-confgen-hyprdots}";
  in {
    Service.ExecStartPre = confgen;
    Service.ExecReload = lib.mkForce confgen;
  };

  home.packages = [self.waybar-confgen-hyprdots];

  impure-config-management.config = lib.genAttrs ["waybar/modules" "waybar/config.ctl"] (n: "config/${n}");

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };

  programs.waybar.style = ''
    @import "${config.xdg.configHome}/waybar/style.mine.css";
  '';
}
