{
  lib-mine,
  config,
  origin,
  pkgs,
  ...
}: let
  inherit (origin.config.meta) flakeRoot;
  secretPath = flakeRoot + "/secrets/users/${config.home.username}";
in
  lib-mine.mkFeature "features.secrets-management" {
    imports = [
      origin.inputs.sops-nix.homeManagerModules.sops
    ];

    config = {
      # TODO(2025-05-09, Max Bolotin): Find a nice abstraction over this module that allows us to define what secrets we are looking for closer to where they are being used, i.e. have the definition of secrets.github_token in the git-config feature model etc
      sops = let
        defaultSops = secretPath + "/default.yaml";
        accountSops = secretPath + "/accounts.yaml";
        vdirSecretDir = "${config.xdg.configHome}/vdirsyncer/secrets";
      in {
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        defaultSopsFile = defaultSops;

        secrets.github_token = {};
        secrets.github_packages_token = {
          path = "${config.xdg.configHome}/.github_packages_token";
        };

        #secrets.ics-personal-url.sopsFile = accountSops;
        #secrets.ics-volvocars-url.sopsFile = accountSops;
        secrets.caldav-ourstudio-clientid = {
          sopsFile = accountSops;
          path = vdirSecretDir + "/caldav-ourstudio-clientid";
        };
        secrets.caldav-ourstudio-clientsecret = {
          sopsFile = accountSops;
          path = vdirSecretDir + "/caldav-ourstudio-clientsecret";
        };
        #secrets.caldav-ourstudio-url.sopsFile = accountSops;
      };

      home.packages = with pkgs; [
        sops
      ];
    };
  }
