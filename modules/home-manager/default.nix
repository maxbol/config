{...}: {
  imports = [
    ./application-modules
    ./application-support
    ./browser-config
    ./darwin-desktop
    ./default-development-environment.nix
    ./git-config.nix
    ./identity.nix
    ./impure-config-management.nix
    ./linux-desktop
    ./linux-theme-defaults.nix
    ./nix-services
    ./replace-runtime-dependencies.nix
    ./secrets-management.nix
    ./terminal-services
    ./theme-config
    ./theme-defaults.nix
    ./tmux-config.nix
  ];
}
