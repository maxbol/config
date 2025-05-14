# config

These are my config files. Unless otherwise specified, they are shared with you under the terms of GPLv3.

## Goals

This nix config repository is designed with the ambition to be as clear, simple and understandable as possible (and thus easy to maintain/modify without breaking things).

* No autoloading - Opt for barelling instead of maintaining inscrutable autoloading code
* Design for 1 use case - my own. No extendability/inheritability by default. If you want to use something, copy it to your own repository and tweak it. You don't want to hold an upstream dependency to someone's dotfiles anyways.
* Locality of behavior - Don't spread code that has to do with one system behavior (like themeing, boot, or whatever) across a bunch of modules in different places. Organize the repo based on what behavior is being controlled, rather than weird nix-like taxonomies (like "regular" modules vs feature modules).
* No namespacing. These are my config files, for whose benefit would I be namespacing them? Opt for legibility instead, flatten everything as much as possible.

---

# Migration from nix-dotfiles

Currently migrating to this repository from my old dotfiles repo, `nix-dotfiles`.

- [x] Packages 
  - [x] clockify-cli
  - [x] clockify-tmux
  - [x] dynachrome
  - [x] hyprdots-kvantum
  - [x] hyprdots-qt5ct
  - [x] nancy
  - [x] rofi-launchers-hyprdots-swwwallselect-patch
  - [x] runcached
  - [x] synp
  - [x] zathura-darwin
  - [x] zathura-darwin-app
- [x] Themes
  - [x] Ayu
  - [x] Blue Nightmare
  - [x] Bluloco
  - [x] Catppuccin
  - [x] Gruvbox
  - [x] Newpaper
  - [x] Oh Lucy
  - [x] Rosepine
  - [x] Tsoding-Mode
- [ ] Home manager modules
  - [x] Themeing
    - [x] App integrations
      - [x] Bat
      - [x] Dunst
      - [x] Dynawall
      - [x] Firefox
      - [x] Fish
      - [x] GTK
      - [x] Hyprland
      - [x] Jankyborders
      - [x] Kitty
      - [x] Linux Destkop Misc
      - [x] Macos-wallpaper
      - [x] Neovim
      - [x] Obsidian
      - [x] Palette.json
      - [x] QT
      - [x] Rofi
      - [x] Sketchybar
      - [x] Starship
      - [x] Tmux
      - [x] VSCode
      - [x] Waybar
      - [x] Wezterm
      - [x] Yazi
      - [x] Zathura
  - [x] Terminal environmnent (shell, bat, starship, kitty, yazi, misc terminal packages)
    - [x] Nix services (direnv, nix-index, comma-with-db, etc)
    - [ ] Calendar services (khal, khard, vdirsyncer, tmux integration?)
    - [x] Git settings
    - [x] Tmux
  - [x] Desktop MacOS - Sketchybar
  - [ ] Destkop Linux - Hyprland/Niri, Dunst, Rofi, Waybar, Wlogout, Swim, etc...
  - [x] Browser - Firefox customizations
  - [ ] Linux user level services
    - [ ] GPG Agent
  - [ ] Applications that require more configuration
    - [x] Neovim
    - [x] Obsidian
    - [ ] Swim
    - [x] Zathura
  - [x] Secrets management (SOPS)
  - [x] Copper File (easy out of store linking to config files)
- [ ] Darwin modules
  - [x] Desktop services (aerospace, jankyborders, sketchybar)
  - [x] Nix services (garbage collection, registry)
  - [ ] Home manager management
- [ ] NixOS modules
  - [ ] Hardware configuration (filesystems, initrd, disko?, impermanence?)
  - [x] System start (plymouth, quiet boot, greetd, bootloader, console font)
  - [x] Core services (pulseaudio, pipewire, bluetooth/blueman, seahorse, openssh, custom udev rules)
  - [x] Destkop services (xdg-portal, dconf, PAM services, i2c, gvfs, devmon, udisks2, upower, power-profiles-daemon, accounts-daemon, glib-networking, opentabletdriver, etc)
  - [x] Secrets management (sops-nix)
  - [x] VPN (tailscale)
  - [ ] Backup (syncthing)
  - [ ] Nix services (nh, garbage collection, registry)
  - [ ] Home manager management




