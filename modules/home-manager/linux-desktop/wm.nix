{
  config,
  pkgs,
  lib,
  lib-mine,
  options,
  # vendor,
  self,
  ...
}:
lib-mine.mkFeature "features.linux-desktop.wm" {
  impure-config-management.config = lib.genAttrs [
    # "hypr/hypridle.conf"
    # "hypr/hyprlock.conf"
    "hypr/animations.conf"
    "hypr/entry.conf"
    "hypr/keybindings.conf"
    # "hypr/nvidia.conf"
    "hypr/plugins.conf"
    "hypr/windowrules.conf"
  ] (n: "config/${n}");

  wayland.windowManager.hyprland = {
    enable = true;
    plugins = with pkgs.hyprlandPlugins; [
      hyprscroller
    ];
    # TODO: this also installs a hyprland package, how does this conflict with the global install
    # package = vendor.hyprland.default;
    # plugins = [
    #   origin.inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
    #   # ...
    # ];
    systemd.enable = true;
    # Needed so that waybar, etc. have a complete environment
    systemd.variables =
      options.wayland.windowManager.hyprland.systemd.variables.default
      ++ [
        "XDG_DATA_DIRS"
        "XDG_CONFIG_DIRS"
        "PATH"
      ];
    # TODO: nvidia patches are no longer needed, but does that extend to the nvidia conf file?
    settings.source = lib.mkMerge [["${config.xdg.configHome}/hypr/entry.conf"]];
  };

  home.packages = with pkgs; [
    self.systemctl-toggle
    self.misc-scripts-hyprdots
    xwaylandvideobridge
    procps
    wl-clipboard
    wl-clipboard-x11
    hyprlock
    hypridle
    brightnessctl
    swappy
    kdePackages.plasma-workspace # necessary for xembedsniproxy, to get wine tray into hyprpanel
  ];

  systemd.user.services.polkit-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.pantheon.pantheon-agent-polkit}/libexec/policykit-1-pantheon/io.elementary.desktop.agent-polkit";
      Restart = "always";
      # TODO: dbus activation isn't working for the Gnome or Elementary (Pantheon) Agent for some reason
      #BusName = "org.freedesktop.PolicyKit1.AuthenticationAgent";
    };

    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.chroma-launch = {
    Unit = {
      Description = "Set up theming scripts";
      After = ["graphical-session-pre.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${config.theme-config.themeDirectory}/active/activate";
      Restart = "no";
    };

    Install.WantedBy = ["hyprland-session.target"];
  };

  theme-config.systemdTarget = "hyprland-session.target";

  services.network-manager-applet.enable = true;
  services.blueman-applet.enable = true;
}
