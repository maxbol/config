{
  pkgs,
  self,
  lib,
  variant ? "latte",
  accent ? "blue",
  accent2 ? "rosewater",
  accent3 ? "mauve",
  accent4 ? "lavender",
  accent5 ? "peach",
  hyprlandOverrides ? p: {},
  hyprpanelTheme ? "catppuccin_mocha",
  waybarOverrides ? p: {},
  rofiOverrides ? p: {},
  tmuxOverrides ? p: {},
  sketchybarOverrides ? p: {},
  neovimOverrides ? p: {},
  makeDesktop,
  ...
}: let
  capitalize = str: "${pkgs.lib.toUpper (builtins.substring 0 1 str)}${builtins.substring 1 (builtins.stringLength str) str}";

  telaMap = {
    "blue" = "blue";
    "flamingo" = "pink";
    "green" = "green";
    "lavender" = "blue";
    "maroon" = "brown";
    "mauve" = "purple";
    "peach" = "orange";
    "pink" = "pink";
    "red" = "red";
    "rosewater" = "pink";
    "sapphire" = "blue";
    "sky" = "blue";
    "teal" = "blue";
    "yellow" = "yellow";
  };

  luminance =
    if variant == "latte"
    then "light"
    else "dark";

  Variant = capitalize variant;
  Accent = capitalize accent;
  Luminance = capitalize luminance;

  palette_ = let
    source = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/palette/823bd0179d491facf8ca368451dddb713926bc0e/palette.json";
      sha256 = "1q1x4j35km0k1nlvsip4hzbjdg306vfjig92nnsnz7kqp9bxb202";
    };
    palette = pkgs.runCommand "catppuccin-${variant}-palette" {inherit variant;} ''
      ${lib.getExe pkgs.jq} ".$variant.colors | map_values(.hex[1:])" ${source} > $out
    '';
  in
    builtins.fromJSON (builtins.readFile palette);
in rec {
  palette = {
    semantic = {
      text = palette_.text;
      text1 = palette_.subtext1;
      text2 = palette_.subtext0;
      overlay = palette_.overlay0;
      surface = palette_.surface0;
      background = palette_.base;
      accent1 = palette_.${accent};
      accent2 = palette_.${accent2};
      accent3 = palette_.${accent3};
      accent4 = palette_.${accent4};
      accent5 = palette_.${accent5};
    };

    accents = {
      inherit (palette_) blue flamingo green lavender maroon mauve peach pink red rosewater sapphire sky teal yellow;
    };

    colors = {
      inherit (palette_) red yellow green blue;
    };

    all = palette_;
  };

  hyprland.colorOverrides = hyprlandOverrides palette;

  waybar.colorOverrides = waybarOverrides palette;

  hyprpanel.theme = {
    package = self.hyprpanel-themes;
    name = hyprpanelTheme;
  };

  rofi.colorOverrides = rofiOverrides palette;

  tmux.colorOverrides = tmuxOverrides palette;

  sketchybar.colorOverrides = sketchybarOverrides palette;

  neovim = neovimOverrides palette;

  desktop = makeDesktop {inherit accent telaMap;};

  gtk = {
    theme.package = pkgs.catppuccin-gtk.override {
      inherit variant;
      accents = [accent];
    };
    theme.name = "catppuccin-${variant}-${accent}-standard";
    hasGtk4Theme = true;
    documentFont = desktop.font;
    colorScheme = "prefer-${luminance}";
  };

  qt = {
    kvantum = {
      package = self.hyprdots-kvantum;
      name = "Catppuccin-${Variant}";
    };

    qtct = {
      package = self.hyprdots-qt5ct;
      name = "Catppuccin-${Variant}";
    };
  };

  kitty = let
    themeFile = "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-${Variant}.conf";
    themeConf = builtins.readFile themeFile;

    themeSource = pkgs.writeText "theme.conf" ''
      ${themeConf}

      ${
        if variant == "latte"
        then ''
          # macos_thicken_font 1
          # background #ccd0da
        ''
        else ""
      }
    '';
  in {
    # font = {
    #   name = "Fira Code";
    #   package = pkgs.fira-code;
    #   size = 16;
    # };
    file."theme.conf".source = themeSource;
  };

  fish.theme = {
    file = "${pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "fish";
      rev = "91e6d6721362be05a5c62e235ed8517d90c567c9";
      hash = "sha256-l9V7YMfJWhKDL65dNbxaddhaM6GJ0CFZ6z+4R6MJwBA=";
    }}/themes/Catppuccin ${Variant}.theme";
    name = "Catppuccin ${Variant}";
  };

  starship.palette = {
    file =
      pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "starship";
        rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
        hash = "sha256-soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
      }
      + /palettes/${variant}.toml;
    name = "catppuccin_${variant}";
  };

  bat.theme = {
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "bat";
      rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
      hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
    };
    file = "Catppuccin-${variant}.tmTheme";
  };

  nvchad.theme = "catppuccin";

  macoswallpaper = {
    wallpaper = ./wallpapers/wallpaper.png;
  };

  swim.wallpaperDirectory = ./wallpapers;
}
