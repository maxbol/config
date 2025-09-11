{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.application-support.intellij" {
  home.packages = with pkgs.jetbrains; [
    datagrip
    rider
  ];

  home.file.".ideavimrc" = {
    text = ''
      set clipboard+=unnamed
    '';
  };
}
