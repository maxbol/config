{...}: {
  imports = [
    ./application-modules
    ./application-support
    ./browser-config
    ./darwin-desktop
    ./git-config.nix
    ./impure-config-management.nix
    ./linux-desktop
    ./nix-services
    ./replace-runtime-dependencies.nix
    ./secrets-management.nix
    ./terminal-services
    ./theme-config
    ./theme-defaults.nix
    ./tmux-config.nix
  ];
}
