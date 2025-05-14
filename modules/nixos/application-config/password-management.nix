{
  lib-mine,
  pkgs,
  lib,
  ...
}:
lib-mine.mkFeature "features.application-config.password-management" ({config, ...}: {
  programs._1password.enable = true;
  programs._1password-gui = {
    package = pkgs._1password-gui;
    enable = true;
    polkitPolicyOwners = lib.attrNames config.users.users;
  };
})
