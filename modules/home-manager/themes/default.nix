{
  pkgs,
  specialArgs,
  ...
}: let
  makeDesktop = {
    accent,
    telaMap ? {},
    iconTheme ? {
      package = pkgs.tela-icon-theme;
      name = "Tela-${telaMap.${accent} or "blue"}";
    },
  }: {
    # Note: this propagatedInputs override should be upstreamed to nixpkgs
    inherit iconTheme;
    cursorTheme.package = pkgs.apple-cursor;
    cursorTheme.name = "macOS";
    cursorTheme.size = 28;
    # font.name = "Cantarell";
    font.name = "DeepMind Sans";
    font.size = 12;
    font.package = pkgs.cantarell-fonts;
    monospaceFont.name = "Aporetic Sans Mono";
    monospaceFont.size = 12;
    monospaceFont.package = specialArgs.vendor.aporetic-kitty.default;
  };

  makeTheme = path: args: (pkgs.callPackage path (specialArgs // args // {inherit makeDesktop;}));
in {
  Ayu-Dark = makeTheme ./ayu {
    waybarOpacity = 0.0;

    neovimOverrides = palette: {
      colorscheme = "ayu-dark";
      background = "dark";
      hlGroupsFg = {
        HLChunk1 = "#" + palette.semantic.accent2;
        HLLineNum1 = "#" + palette.semantic.accent2;
        LineNr = "#" + palette.semantic.text2;
        IncSearch = "#" + palette.semantic.background;
        Function = "#" + palette.accents.mauve;
        BlinkCmpGhostText = "#" + palette.semantic.text1;
      };
      hlGroupsBg = {
        Visual = "#" + palette.semantic.text2;
        IncSearch = "#" + palette.accents.peach;
      };
    };
  };

  Ayu-Mirage =
    makeTheme ./ayu
    {
      variant = "mirage";
      wallpaper = ./ayu/wallpapers/mirage/wallpaper.png;

      waybarOpacity = 0.0;

      neovimOverrides = palette: {
        colorscheme = "ayu-mirage";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#" + palette.semantic.accent1;
          HLLineNum1 = "#" + palette.semantic.accent1;
          Function = "#" + palette.accents.mauve;
          BlinkCmpGhostText = "#" + palette.semantic.text1;
        };
        hlGroupsBg = {
          Visual = "#" + palette.semantic.text2;
        };
      };
    };

  # Blue-Nightmare = makeTheme ./blue-nightmare {};

  Bluloco-Dark = makeTheme ./bluloco {luminanceVariant = "dark";};

  Catppuccin-Latte =
    makeTheme ./catppuccin
    {
      variant = "latte";

      hyprlandOverrides = palette: {
        active1 = palette.accents.rosewater;
        active2 = palette.accents.mauve;

        inactive1 = palette.accents.lavender;
        inactive2 = palette.accents.teal;
      };

      hyprpanelTheme = "catppuccin_latte";

      rofiOverrides = palette: {
        main-background = palette.all.crust;
        highlight = palette.accents.flamingo;
        highlight-text = palette.all.base;
      };

      neovimOverrides = palette: {
        colorscheme = "catppuccin-latte";
        background = "light";
        hlGroupsFg = {
          HLChunk1 = "#" + palette.semantic.accent2;
          HLLineNum1 = "#" + palette.semantic.accent2;
        };
        hlGroupsBg = {
          CursorLine = "#bcc0cc";
        };
      };
    };

  Catppuccin-Mocha =
    makeTheme ./catppuccin
    {
      variant = "mocha";

      hyprlandOverrides = palette: {
        active1 = palette.accents.mauve;
        active2 = palette.accents.rosewater;
        inactive1 = palette.accents.lavender;
        inactive2 = "6c7086";
      };

      hyprpanelTheme = "catppuccin_mocha";

      rofiOverrides = palette: {
        main-background = palette.all.crust;
        text = "cdd6f4";
        border = palette.accents.mauve;
        highlight = palette.accents.lavender;
        highlight-text = palette.all.crust;
      };

      neovimOverrides = palette: {
        colorscheme = "catppuccin-macchiato";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#" + palette.semantic.accent2;
          HLLineNum1 = "#" + palette.semantic.accent2;
        };
      };

      tmuxOverrides = palette: {
        status_window_inactive_bg = palette.semantic.surface;
        status_modules_outer_bg = palette.semantic.surface;
      };
    };

  Gruvbox-Dark = makeTheme ./gruvbox {
    luminanceVariant = "dark";
    neovimOverrides = palette: {
      hlGroupsFg = {
        HLChunk1 = "#8ec07c";
        HLLineNum1 = "#8ec07c";
        BlinkCmpGhostText = "#" + palette.semantic.text1;
      };
      hlGroupsBg = {
        TelescopeSelection = "#427b58";
      };
    };
  };
  Gruvbox-Light = makeTheme ./gruvbox {
    luminanceVariant = "light";
  };

  Newpaper-Light = makeTheme ./newpaper {
    luminanceVariant = "light";
    neovimOverrides = _: {
      background = "light";
      extraCmds = ["NewpaperLight"];
    };
  };

  Oh-Lucy =
    makeTheme ./oh-lucy
    {
      neovimOverrides = palette: {
        colorscheme = "oh-lucy";
      };
    };

  Oh-Lucy-Evening =
    makeTheme ./oh-lucy
    {
      variant = "evening";
      neovimOverrides = palette: {
        colorscheme = "oh-lucy-evening";
      };
    };

  Rose-Pine =
    makeTheme ./rose-pine
    {
      variant = "pine";
      waybarOpacity = 0.0;
      niriOverrides = palette: {
        active-border = palette.semantic.text2;
      };
      # firefoxOverrides = palette: {
      #   border_color_active = palette.semantic.text2;
      # };
      neovimOverrides = palette: {
        colorscheme = "rose-pine-main";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
          CursorLineNr = "#" + palette.semantic.text;
        };
        hlGroupsBg = {
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
        hlClear = ["CursorLine"];
      };
    };

  Rose-Pine-Eclipse =
    makeTheme ./rose-pine
    {
      variant = "eclipse";
      hyprpanelTheme = "rose_pine_moon";
      neovimOverrides = palette: {
        colorscheme = "rose-pine-moon";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
          CursorLineNr = "#" + palette.semantic.text;
        };
        hlGroupsBg = {
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
        hlClear = ["CursorLine"];
      };

      wallpaper = ./rose-pine/wallpapers/eclipse/wallpaper.png;
      kittyOverrides.file."theme.conf".source = ./rose-pine/eclipse-kitty.conf;
    };

  Rose-Pine-Moon =
    makeTheme ./rose-pine
    {
      variant = "moon";
      hyprpanelTheme = "rose_pine_moon";
      neovimOverrides = palette: {
        colorscheme = "rose-pine-moon";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
          CursorLineNr = "#" + palette.semantic.text;
        };
        hlGroupsBg = {
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
        hlClear = ["CursorLine"];
      };
      noctaliaOverrides = _: {
        predefinedColorscheme = "Rosepine";
      };
      wallpaper = ./rose-pine/wallpapers/moon/wallpaper.png;
    };

  Rose-Pine-Dawn = makeTheme ./rose-pine {
    variant = "dawn";
    luminanceVariant = "light";
    noctaliaOverrides = _: {
      predefinedColorscheme = "Rosepine";
    };
    neovimOverrides = palette: {
      colorscheme = "rose-pine-dawn";
      background = "light";
    };
  };

  Tsoding-Mode = makeTheme ./tsoding-mode {};
}
