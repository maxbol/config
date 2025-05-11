{...}: {
  imports = [
    ./browser-config
    ./darwin-desktop
    ./git-config.nix
    ./impure-config-management.nix
    ./nix-services
    ./secrets-management.nix
    ./terminal-services
    ./tmux-config.nix
  ];
}
