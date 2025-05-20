{
  pkgs,
  variant ? "dark",
  gtkThemeVariant ? (
    if variant == "dark"
    then "Ayu-Dark"
    else "Ayu"
  ),
  kvantumThemeVariant ? (
    if variant == "dark"
    then "AyuDark"
    else "AyuMirage"
  ),
  accent ? "orange",
  accent2 ? "lightblue",
  accent3 ? "yellow",
  hyprlandOverrides ? p: {},
  waybarOverrides ? p: {},
  rofiOverrides ? p: {},
  tmuxOverrides ? p: {},
  sketchybarOverrides ? p: {},
  neovimOverrides ? p: {},
  wallpaper ? ./wallpapers/dark/wallpaper.jpg,
  lib-mine,
  makeDesktop,
  ...
}: let
  variants = [
    "dark"
    "mirage"
    "light"
  ];

  ayuTmTheme = pkgs.fetchFromGitHub {
    owner = "dempfi";
    repo = "ayu";
    rev = "3.2.2";
    sha256 = "sha256-BDkZ7RsUx8t20n7i6htCQM/vPOR89guWfAOaCXi1oC0=";
  };

  ayuFishTheme = pkgs.fetchFromGitHub {
    owner = "edouard-lopez";
    repo = "ayu-theme.fish";
    rev = "v2.0.0";
    sha256 = "sha256-rx9izD2pc3hLObOehuiMwFB4Ta5G1lWVv9Jdb+JHIz0=";
  };

  ayuYaziFlavor = pkgs.fetchFromGitHub {
    owner = "kmlupreti";
    repo = "ayu-dark.yazi";
    rev = "441a38d56123e8670dd4962ab126f6d9f1942f40";
    sha256 = "sha256-AaTCYzZe90Wri/jnku8pO2hXTFhqBPlAGBo5U9gwfSs=";
  };

  ayuPaletteToJson = pkgs.buildNpmPackage {
    pname = "ayu-palette-to-json";
    version = "1.0.0";
    src = ./ayuPalette2Json;
    npmDepsHash = "sha256-RHOOeJ9jpBF5SwKFcGUPBJK8E/u9XmpSKR4MJzz+Tv8=";
    postInstall = ''
      cp $out/lib/node_modules/ayupalette2json/dist/palette.json $out/palette.json
    '';
  };

  ayuPaletteJson = pkgs.lib.pipe "${ayuPaletteToJson}/palette.json" [
    builtins.readFile
    builtins.fromJSON
  ];

  ayuKvantum = let
    src = pkgs.fetchFromGitHub {
      owner = "dnordstrom";
      repo = "dotfiles-as-files";
      rev = "b69b1abf1ad9f6c4f43e6b0a3e5292d932f0831c";
      hash = "sha256-+Lk/5yZecoraFzJigUz8jSknU34P8A2kL4L0q2zSlmw=";
    };
  in
    pkgs.runCommand "ayu-kvantum" {} ''
      mkdir -p $out/share/Kvantum
      cp -r ${src}/kvantum/* $out/share/Kvantum
    '';

  toChromaPalette = jsonPalette: rec {
    colors = {
      red = jsonPalette.syntax.markup;
      green = jsonPalette.syntax.string;
      yellow = jsonPalette.common.accent;
      blue = jsonPalette.syntax.entity;
    };

    accents = {
      inherit (colors) red green yellow blue;
      lightblue = jsonPalette.syntax.tag;
      teal = jsonPalette.syntax.regexp;
      orange = jsonPalette.syntax.keyword;
      grey = jsonPalette.syntax.comment;
      mauve = jsonPalette.syntax.constant;
      peach = jsonPalette.syntax.operator;
    };

    semantic = {
      text = jsonPalette.editor.fg;
      text1 = jsonPalette.ui.fg;
      text2 = jsonPalette.ui.selection.active;
      overlay = jsonPalette.editor.bg;
      surface = jsonPalette.ui.panel.bg;
      background = jsonPalette.ui.bg;
      accent1 = accents.${accent};
      accent2 = accents.${accent2};
      accent3 = accents.${accent3};
    };
  };

  allPalettes = builtins.foldl' (all: v: all // {${v} = toChromaPalette (ayuPaletteJson.${v});}) {} variants;

  telaMap = {
    "red" = "red";
    "green" = "green";
    "yellow" = "yellow";
    "blue" = "blue";
    "purple" = "mauve";
    "aqua" = "teal";
    "orange" = "orange";
  };

  mkStarshipPalette = v: let
    p = allPalettes.${v};
  in ''
    [palettes.ayu_${v}]
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
    purple = "#${p.accents.mauve}"
    aqua = "#${p.accents.teal}"
    orange = "#${p.accents.yellow}"
  '';

  starshipPalettes = pkgs.writeText "starship-palettes.toml" (pkgs.lib.concatStringsSep "\n\n" (map mkStarshipPalette variants));
in rec {
  palette = allPalettes.${variant};

  hyprland.colorOverrides = hyprlandOverrides palette;

  waybar.colorOverrides = waybarOverrides palette;

  rofi.colorOverrides = rofiOverrides palette;

  tmux.colorOverrides = tmuxOverrides palette;

  sketchybar.colorOverrides = sketchybarOverrides palette;

  yazi.flavor = ayuYaziFlavor;
  yazi.generateThemeTomlFromPalette = false;

  neovim = neovimOverrides palette;

  dynawall.shader = "monterrey2";
  dynawall.colorOverrides = {
    accents = [
      ("#" + palette.accents.blue)
      ("#" + palette.accents.lightblue)
      ("#" + palette.accents.teal)
      ("#" + palette.accents.grey)
      ("#" + palette.accents.mauve)
    ];
  };

  desktop = makeDesktop {inherit accent telaMap;};

  gtk = {
    theme = {
      package = pkgs.ayu-theme-gtk;
      name = gtkThemeVariant;
    };
    documentFont = desktop.font;
    colorScheme = "prefer-dark";
  };

  qt.kvantum = {
    package = ayuKvantum;
    name = kvantumThemeVariant;
  };

  kitty = let
    confName =
      if variant == "dark"
      then "ayu.conf"
      else "ayu_${variant}.conf";
    themeFile = "${pkgs.kitty-themes}/share/kitty-themes/themes/${confName}";
    themeConf = builtins.readFile themeFile;

    themeSource = pkgs.writeText "theme.conf" ''
      ${themeConf}
      ${
        if variant == "latte"
        then ''
          macos_thicken_font 1
        ''
        else ""
      }
    '';
  in {
    file."theme.conf".source = themeSource;
  };

  starship.palette = {
    file = starshipPalettes;
    name = "ayu_${variant}";
  };

  bat.theme = {
    src = ayuTmTheme;
    file = "ayu-${variant}.tmTheme";
  };

  fish.theme = {
    file = "${ayuFishTheme}/conf.d/ayu-${variant}.fish";
    name = "ayu_${variant}";
  };

  macoswallpaper = {
    inherit wallpaper;
  };

  swim.wallpaperDirectory = lib-mine.path.dirname wallpaper;
}
