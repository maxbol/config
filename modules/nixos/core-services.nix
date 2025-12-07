{
  lib-mine,
  pkgs,
  ...
}:
lib-mine.mkFeature "features.core-services" {
  hardware = {
    # pulseaudio = {
    #   enable = false;
    #   extraConfig = "
    #     load-module module-switch-on-connect
    #     ";
    #   support32Bit = true;
    # };

    bluetooth = {
      enable = true;
      input = {
        General = {
          UserspaceHID = true;
        };
      };
      settings = {
        General = {
          DiscoverableTimeout = 0;
          MaxConnections = 10;
        };
      };
    };
    i2c.enable = true;

    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      wireplumber.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    blueman.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    accounts-daemon.enable = true;

    gnome = {
      glib-networking.enable = true;
      gnome-keyring.enable = true;
    };

    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [
        # No RSA host keys.
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };

  security = {
    rtkit.enable = true;
  };

  virtualisation = {
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users.groups = {
    docker = {};
    plugdev = {};
  };

  networking = {
    networkmanager.enable = true;
    wireless.iwd.enable = true;
    nameservers = ["8.8.4.4" "8.8.8.8"];
  };

  programs.seahorse.enable = true;

  programs.git.enable = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
    opentabletdriver
    pulseaudio
    seahorse
    wireplumber
  ];

  environment.etc."wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
    bluez_monitor.properties = {
      ["bluez5.enable-sbc-xq"] = false,
      ["bluez5.enable-msbc"] = true,
      ["bluez5.enable-hw-volume"] = true,
      ["bluez5.codecs"] = [ "aac" ]
    }
  '';
}
