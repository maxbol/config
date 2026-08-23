{
  origin,
  lib,
  lib-mine,
  self,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.system-start" ({config, ...}: let
  cfg = config.features.system-start;
in {
  imports = [
    origin.inputs.dms.nixosModules.greeter
  ];
  options = with lib; {
    defaultUser = mkOption {
      type = types.str;
      description = ''
        The username of the user to be logged in by default
      '';
    };
  };
  config = {
    boot.kernelParams = [
      # Silences boot messages
      "quiet"
      # Silences successfull systemd messages from the initrd
      # "rd.systemd.show_status=false"
      # Silence systemd version number in initrd
      # "rd.udev.log_level=0"
      "udev.log_level=0"
      # Silence systemd version number
      # "udev.log_priority=3"
      # If booting fails drop us into a shell where we can investigate
      "boot.shell_on_fail"
      # "plymouth.debug"
    ];
    # Silence dmesg
    boot.consoleLogLevel = 0;
    # Remove extra NixOS logging from the initrd
    boot.initrd.verbose = false;

    # Show a splash screen during boot
    boot.plymouth = let
      theme = "bgrt";
      # theme = "spinner";
      # theme = "circle_flow";
    in {
      enable = true;
      inherit theme;
      # themePackages = [(pkgs.adi1090x-plymouth-themes.override {selected_themes = [theme];})];
    };

    boot.loader = {
      systemd-boot.enable = true;
      # systemd-boot.editor = false;
      timeout = 0;
      efi.canTouchEfiVariables = true;
    };

    boot.initrd.systemd.enable = true;

    # # Arbitrarily extend boot process (useful when debugging/testing plymouth)
    # systemd.services.extend-boot-process = {
    #   serviceConfig.Type = "oneshot";
    #   script = "sleep 10";
    #   before = ["display-manager.service"];
    #   wantedBy = ["display-manager.service"];
    # };

    # services.greetd = {
    #   enable = true;
    #   settings = rec {
    #     initial_session = {
    #       command = "${lib.getExe pkgs.uwsm} start -S -F /run/current-system/sw/bin/Hyprland";
    #       # command = lib.getExe pkgs.hyprland;
    #       user = cfg.defaultUser;
    #     };
    #     default_session = initial_session;
    #   };
    # };

    programs.uwsm.enable = true;

    services.displayManager.dms-greeter = {
      enable = true;
      # Without this the greeter falls back to nixpkgs' dms-shell, which is
      # older than the one the session runs: its generated niri config still
      # carries a `debug { keep-max-bpc-unchanged }` node that niri has since
      # removed, so the greeter's niri rejects the config and comes up
      # unconfigured, never spawning the greeter itself.
      package = origin.inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
      compositor = {
        name = "niri";
      };
      configHome = "/home/max";
    };

    # services.xserver.displayManager.gdm = {
    #   enable = true;
    # };

    # services.displayManager.sddm = {
    #   enable = true;
    #   wayland.enable = true;
    # };

    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
    };

    environment.systemPackages = with pkgs; [
      gdm-settings
    ];
  };
})
