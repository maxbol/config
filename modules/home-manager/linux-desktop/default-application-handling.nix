{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.default-application-handling" {
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    mimeo
  ];
}
