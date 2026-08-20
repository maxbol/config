{
  pkgs,
  self,
  variant ? "default",
  accent ? "red",
  accent2 ? "green",
  accent3 ? "blue",
  accent4 ? "pink",
  accent5 ? "teal",
  neovimOverrides ? p: {},
  makeDesktop,
  ...
}: let
  variantOptions = [
    "default"
    "evening"
  ];

  palsrc = {
    default = {
      fg = "d7d7d7"; # #D7D7D7
      bg = "1b1d26"; # #1B1D26
      none = "1b1d26"; # #1B1D26
      dark = "14161d"; # #14161D
      comment = "5e6173"; # #5E6173
      popup_back = "515761"; # #515761
      cursor_fg = "d7d7d7"; # #D7D7D7
      context = "515761"; # #515761
      cursor_bg = "aeafad"; # #AEAFAD
      accent = "bbbbbb"; # #BBBBBB
      diff_add = "8cd881"; # #8CD881
      diff_change = "6caec0"; # #6CAEC0
      cl_bg = "707891"; # #707891
      diff_text = "568bb4"; # #568BB4
      line_fg = "555b6c"; # #555B6C
      line_bg = "1b1d26"; # #1B1D26
      gutter_bg = "1b1d26"; # #1B1D26
      non_text = "606978"; # #606978
      selection_bg = "5e697e"; # #5E697E
      selection_fg = "495163"; # #495163
      vsplit_fg = "cccccc"; # #cccccc
      vsplit_bg = "21252d"; # #21252D
      visual_select_bg = "272932"; # #272932
      red_key_w = "fb7da7"; # #FB7DA7
      red_err = "d95555"; # #D95555
      green_func = "74c7a4"; # #74C7A4
      green = "76c5a4"; # #76C5A4
      blue_type = "8dbbd3"; # #8DBBD3
      black1 = "272932"; # #272932
      black = "14161d"; # #14161D
      white1 = "d7d7d7"; # #D7D7D7
      white = "e9e9e9"; # #E9E9E9
      gray_punc = "7c7e8c"; # #7C7E8C
      gray2 = "6e7380"; # #6E7380
      gray1 = "343842"; # #343842
      gray = "21252d"; # #21252D
      orange = "e0828d"; # #E0828D
      boolean = "af98e6"; # #AF98E6
      orange_wr = "e39a65"; # #E39A65
      pink = "bda9d4"; # #BDA9D4
      yellow = "e3cf65"; # #E3CF65
    };
    evening = {
      fg = "ded7d0"; # #DED7D0
      bg = "1e1d23"; # #1E1D23
      none = "1e1d23"; # #1E1D23
      dark = "1a191e"; # #1A191E
      comment = "686069"; # #686069
      popup_back = "515761"; # #515761
      cursor_fg = "ded7d0"; # #DED7D0
      context = "515761"; # #515761
      cursor_bg = "aeafad"; # #AEAFAD
      accent = "bbbbbb"; # #BBBBBB
      diff_add = "8cd881"; # #8CD881
      diff_change = "6caec0"; # #6CAEC0
      cl_bg = "524a51"; # #524A51
      diff_text = "568bb4"; # #568BB4
      line_fg = "524a51"; # #524A51
      line_bg = "1e1d23"; # #1E1D23
      gutter_bg = "1e1d23"; # #1E1D23
      non_text = "7f737d"; # #7F737D
      selection_bg = "817081"; # #817081
      selection_fg = "615262"; # #615262
      vsplit_fg = "cccccc"; # #cccccc
      vsplit_bg = "2e2930"; # #2E2930
      visual_select_bg = "29292e"; # #29292E
      red_key_w = "ff7da3"; # #FF7DA3
      red_err = "d95555"; # #D95555
      green_func = "7ec49d"; # #7EC49D
      green = "7ec49d"; # #7EC49D
      blue_type = "8bb8d0"; # #8BB8D0
      black1 = "29292e"; # #29292E
      black = "1a191e"; # #1A191E
      white1 = "ded7d0"; # #DED7D0
      white = "ded7d0"; # #DED7D0
      gray_punc = "938884"; # #938884
      gray2 = "7f737d"; # #7F737D
      gray1 = "413e41"; # #413E41
      gray = "322f32"; # #322F32
      orange = "e0828d"; # #E0828D
      boolean = "b898dd"; # #B898DD
      orange_wr = "e39a65"; # #E39A65
      pink = "bda9d4"; # #BDA9D4
      yellow = "efd472"; # #EFD472
    };
  };

  mkPalette = palette_: rec {
    semantic = {
      text = palette_.fg;
      text1 = palette_.gray_punc;
      text2 = palette_.gray2;
      overlay = palette_.gray1;
      surface = palette_.black1;
      background = palette_.bg;
      accent1 = accents.${accent};
      accent2 = accents.${accent2};
      accent3 = accents.${accent3};
      accent4 = accents.${accent4};
      accent5 = accents.${accent5};
    };
    accents = {
      inherit (colors) red green blue yellow;
      mauve = palette_.boolean;
      pink = palette_.pink;
      orange = palette_.orange_wr;
      teal = palette_.diff_change;
    };
    colors = {
      red = palette_.red_key_w;
      green = palette_.green;
      blue = palette_.blue_type;
      yellow = palette_.yellow;
    };
  };

  allPalettes = {
    default = mkPalette palsrc.default;
    evening = mkPalette palsrc.evening;
  };

  mkStarshipPalette = v: let
    p = allPalettes.${v};
  in ''
    [palettes.oh-lucy_${v}]
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
  telaMap = {
    "red" = "red";
    "green" = "green";
    "yellow" = "yellow";
    "blue" = "blue";
  };
in rec {
  desktop = makeDesktop {inherit accent telaMap;};

  # TODO(2025-05-19, Max Bolotin): Copying this from gruvbox for now, should be replace with theme specific
  gtk = {
    theme.package = pkgs
      .gruvbox-gtk-theme
      .overrideAttrs (prev: {propagatedUserEnvPkgs = prev.propagatedUserEnvPkgs ++ [pkgs.gnome-themes-extra];});
    theme.name = "Gruvbox-Dark";
    documentFont = desktop.font;
    colorScheme = "prefer-dark";
  };

  qt = {
    kvantum = {
      package = self.hyprdots-kvantum;
      name = "Gruvbox-Retro";
    };
  };

  palette = allPalettes.${variant};

  # oh-lucy.nvim ships no lualine theme, so lualine falls back to its `auto`
  # theme, which derives section colors from grey source highlights (PmenuSel,
  # StatusLine, ...) and leaves grey blocks smattered across the statusline.
  # Patching individual `lualine_*` highlight groups is unreliable because
  # lualine caches its lazily-created separator ("transitional") highlights and
  # regenerates them from the section groups on redraw, clobbering post-hoc
  # `:hi` overrides. Instead we hand lualine a complete theme *table*, which it
  # uses to regenerate every group (sections, components and separators)
  # consistently. `neomax/plugins/theme.lua` reads this table back per
  # colorscheme from `vim.g.neomax_lualine`, so it never leaks into other
  # themes.
  neovim = let
    p = palette;
    hex = c: "#" + c;

    bgColor = hex p.semantic.background;
    surfaceColor = hex p.semantic.surface;
    textColor = hex p.semantic.text;
    subtleColor = hex p.semantic.text1;
    dimColor = hex p.semantic.text2;

    # Per-mode accent for the `a`/`z` (mode indicator) sections.
    modeColors = {
      normal = p.semantic.accent1;
      insert = p.accents.green;
      visual = p.accents.mauve;
      replace = p.accents.orange;
      command = p.accents.yellow;
      terminal = p.accents.teal;
    };

    # A lua fragment `<mode>={a=..,b=..,c=..}` for one active mode. Sections:
    # a = mode accent (dark bold text), b = dark surface, c = background.
    luaMode = mode: accent: ''
      ${mode}={a={fg='${bgColor}',bg='${hex accent}',gui='bold'},b={fg='${textColor}',bg='${surfaceColor}'},c={fg='${subtleColor}',bg='${bgColor}'}}'';

    modeFragments =
      pkgs.lib.mapAttrsToList luaMode modeColors
      # Inactive window: fully muted, no accent.
      ++ ["inactive={a={fg='${dimColor}',bg='${surfaceColor}'},b={fg='${dimColor}',bg='${surfaceColor}'},c={fg='${dimColor}',bg='${bgColor}'}}"];

    themeTable = "{${pkgs.lib.concatStringsSep "," modeFragments}}";

    colorscheme = (neovimOverrides palette).colorscheme or "oh-lucy";

    registerLualineTheme = "lua local o=vim.g.neomax_lualine or {}; o['${colorscheme}']=${themeTable}; vim.g.neomax_lualine=o; require('lualine').setup()";
  in
    {
      hlGroupsBg = {
        Cursor = dimColor;
      };
      extraCmds = [registerLualineTheme];
    }
    // (neovimOverrides palette);

  ghostty.autoGenerate.enable = true;

  kitty = {
    autoGenerate = {
      enable = true;
      colorOverrides = {
        color0 = palette.semantic.background;
        color1 = palette.accents.red;
        color2 = palette.accents.green;
        color3 = palette.accents.blue;
        color4 = palette.accents.yellow;
        color5 = palette.accents.mauve;
        color6 = palette.accents.teal;
        color7 = palette.accents.pink;
        color8 = palette.semantic.overlay;
        color9 = palette.accents.orange;
        color10 = palette.accents.red;
        color11 = palette.accents.green;
        color12 = palette.accents.blue;
        color13 = palette.accents.yellow;
        color14 = palette.accents.mauve;
        color15 = palette.semantic.text2;
      };
    };
  };

  starship.palette = let
    starshipPalettes = pkgs.writeText "starship-palettes.toml" (pkgs.lib.concatStringsSep "\n\n" (map mkStarshipPalette variantOptions));
  in {
    file = starshipPalettes;
    name = "oh-lucy_${variant}";
  };

  bat = {
    theme = null;
    colorOverrides = {};
  };

  macoswallpaper = {
    wallpaper = ./wallpapers/wallpaper.png;
  };

  swim.wallpaperDirectory = ./wallpapers;
}
