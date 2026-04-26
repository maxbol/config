{
  pkgs,
  self,
  luminanceVariant ? "dark",
  accent ? "sky",
  accent2 ? "leaf",
  accent3 ? "water",
  accent4 ? "ocean",
  accent5 ? "blossom",
  neovimOverrides ? p: {},
  makeDesktop,
  lib-mine,
  ...
}: let
  luminanceOptions = [
    "dark"
    "light"
  ];

  palsrc = {
    dark = {
      text = "c6d5cf";
      text1 = "98a39e";
      text2 = "98a39e";
      bg = "0f191f";
      bg1 = "20303a";
      bg2 = "263945";
      rose = "de6e7c";
      bright_rose = "e8838f";
      leaf = "90ff6b";
      bright_leaf = "a0ff85";
      wood = "b77e64";
      bright_wood = "d68c67";
      water = "8190d4";
      bright_water = "92a0e2";
      blossom = "b279a7";
      bright_blossom = "cf86c1";
      sky = "66a5ad";
      bright_sky = "65b8c1";
      ocean = "3b5362";
    };
    light = {
      text = "202e18";
      text1 = "415934";
      text2 = "415934";
      bg = "e5ede6";
      bg1 = "c2cfc4";
      bg2 = "b3c6b6";
      rose = "a8334c";
      bright_rose = "94253e";
      leaf = "567a30";
      bright_leaf = "3f5a22";
      wood = "944927";
      bright_wood = "803d1c";
      water = "286486";
      bright_water = "1d5573";
      blossom = "88507d";
      bright_blossom = "7b3b70";
      sky = "3b8992";
      bright_sky = "2b747c";
      ocean = "3b5362";
    };
  };

  mkPalette = palette_: rec {
    semantic = {
      text = palette_.text;
      text1 = palette_.text1;
      text2 = palette_.text2;
      overlay = palette_.bg2;
      surface = palette_.bg1;
      background = palette_.bg;
      accent1 = accents.${accent};
      accent2 = accents.${accent2};
      accent3 = accents.${accent3};
      accent4 = accents.${accent4};
      accent5 = accents.${accent5};
    };
    accents = {
      inherit (palette_) rose leaf wood water blossom sky bright_rose bright_leaf bright_wood bright_water bright_blossom bright_sky ocean;
      inherit (colors) red green blue yellow;
      mauve = palette_.blossom;
      teal = palette_.sky;
      orange = palette_.wood;
      purple = palette_.blossom;
      aqua = palette_.sky;
    };
    colors = {
      red = palette_.rose;
      green = palette_.leaf;
      blue = palette_.water;
      yellow = palette_.wood;
    };
  };

  allPalettes = {
    dark = mkPalette palsrc.dark;
    light = mkPalette palsrc.light;
  };

  mkStarshipPalette = v: let
    p = allPalettes.${v};
  in ''
    [palettes.neobones_${v}]
    text = "#${p.semantic.text}"
    subtext0 = "#${p.semantic.text1}"
    subtext1 = "#${p.semantic.text2}"
    surface0 = "#${p.semantic.background}"
    surface1 = "#${p.semantic.surface}"
    surface2 = "#${p.semantic.surface}"
    overlay0 = "#${p.semantic.overlay}"
    overlay1 = "#${p.semantic.overlay}"
    overlay2 = "#${p.semantic.overlay}"
    red = "#${p.colors.red}"
    green = "#${p.colors.green}"
    yellow = "#${p.colors.yellow}"
    blue = "#${p.colors.blue}"
    purple = "#${p.accents.purple}"
    aqua = "#${p.accents.aqua}"
    orange = "#${p.accents.orange}"
  '';
in rec {
  palette = allPalettes.${luminanceVariant};

  desktop = makeDesktop {inherit accent;};

  gtk = {
    theme.package =
      pkgs
      .adw-gtk3;
    theme.name = "adw-gtk3-${luminanceVariant}";
    documentFont = desktop.font;
    # colorScheme = "prefer-light"; # A quirk of the GTK theme
    colorScheme = "prefer-${luminanceVariant}";
  };

  qt = {
    kvantum = {
      package = self.hyprdots-kvantum;
      name = "Gruvbox-Retro";
    };
  };

  neovim =
    {
      colorscheme = "neobones";
      background = luminanceVariant;
    }
    // (neovimOverrides palette);

  # noctalia.colorOverrides = {
  #   mSurface = "04080a";
  # };

  kitty = {
    autoGenerate = {
      enable = true;
      colorOverrides = {
        color0 = palette.semantic.background;
        color1 = palette.accents.rose;
        color2 = palette.accents.leaf;
        color3 = palette.accents.wood;
        color4 = palette.accents.water;
        color5 = palette.accents.blossom;
        color6 = palette.accents.sky;
        color7 = palette.semantic.text;
        color8 = palette.semantic.overlay;
        color9 = palette.accents.bright_rose;
        color10 = palette.accents.bright_leaf;
        color11 = palette.accents.bright_wood;
        color12 = palette.accents.bright_water;
        color13 = palette.accents.bright_blossom;
        color14 = palette.accents.bright_sky;
        color15 = palette.semantic.text2;
      };
    };
  };

  starship.palette = let
    starshipPalettes = pkgs.writeText "starship-palettes.toml" (pkgs.lib.concatStringsSep "\n\n" (map mkStarshipPalette luminanceOptions));
  in {
    file = starshipPalettes;
    name = "neobones_${luminanceVariant}";
  };

  bat = {
    theme = null;
    colorOverrides = {};
  };

  swim.wallpaperDirectory = ./wallpapers;
}
