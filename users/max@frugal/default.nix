{
  lib-mine,
  pkgs,
  config,
  vendor,
  self,
  origin,
  ...
}: let
  nixpkgs-unstable = import origin.inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config = {allowUnfree = true;};
  };
in rec {
  home.stateVersion = "24.11";
  home.username = "max";
  home.homeDirectory = "/home/max/";

  impure-config-management.symlink.enable = true;
  impure-config-management.symlink.base = "${home.homeDirectory}/src/config";

  features.browser-config.enable = true;
  features.secrets-management.enable = true;
  features.application-support.enable = true;
  features.default-development-environment.enable = true;
  features.office-suite.enable = true;
  features.streaming.enable = true;
  features.git-config.enable = true;
  features.linux-desktop.enable = true;
  features.linux-desktop.notifications.enable = false;
  features.linux-desktop.waybar.enable = false;
  features.linux-desktop.walker.enable = false;
  features.nix-services.enable = true;
  features.terminal-services.enable = true;
  features.terminal-services.terminal-config.enable = true;
  features.linux-theme-defaults.enable = true;
  features.tmux-config.enable = true;

  identity = {
    userImage = ./image.jpg;
  };

  programs.git.settings.user = {
    name = "Max Bolotin";
    email = "maks.bolotin@gmail.com";
  };

  home.sessionVariables = {
    NH_HOME_FLAKE = "${config.home.homeDirectory}/src/config";
  };

  xdg.mimeApps = let
    apps =
      lib-mine.mime.bindImageTypes ["org.libvips.vipsdisp.desktop"]
      // lib-mine.mime.bindVideoTypes ["io.github.celluloid_player.Celluloid.desktop"]
      // lib-mine.mime.bindTextTypes ["nvim.desktop"]
      // lib-mine.mime.bindBrowserTypes ["firefox.desktop"]
      // {
        "application/pdf" = ["org.pwmt.zathura.desktop"];
        "model/obj" = ["blender.desktop"];
        "model/gltf-binary" = ["f3d.desktop"];
        "model/gltf+json" = ["f3d.desktop"];
        "inode/directory" = ["org.gnome.Nautilus.desktop"];
        "inode/symlink" = ["org.gnome.Nautilus.desktop"];
        "text/csv" = ["onlyoffice-desktopeditors.desktop"];
      };
  in {
    associations.added = apps;
    defaultApplications = apps;
  };

  # Various application packages that can be "stupidly" added,
  # that this specific user is interested in, and that doesn't
  # need/gain anything from having a separate feature module
  home.packages = with pkgs; let
    azure = azure-cli.withExtensions (with azure-cli.extensions; [
      containerapp
      k8s-extension
      k8s-runtime
      fzf
    ]);
  in [
    aseprite
    azure
    blender
    cachix
    celluloid
    nixpkgs-unstable.claude-code
    discord
    emacs
    f3d
    ffmpeg
    file
    file-roller
    gettext
    grim
    kooha
    krita
    kubectl
    kubeseal
    kustomize
    mpv
    nautilus
    postman
    self.wayscriber
    slack
    slurp
    thunderbird
    unzip
    vendor.wooz.default
    vendor.zen-browser.default
    vipsdisp
    vlc
    wdisplays
    yq-go
    zed-editor
    zenity
    zsnes2

    (python3.withPackages
      (python-pkgs:
        with python-pkgs; [
          pandas
          openpyxl
        ]))
  ];
}
