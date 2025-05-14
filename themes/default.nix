{pkgs, ...} @ themeArgs: {
  Ayu-Dark = import ./ayu (themeArgs
    // {
      neovimOverrides = palette: {
        colorscheme = "ayu-dark";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#" + palette.semantic.accent2;
          HLLineNum1 = "#" + palette.semantic.accent2;
          LineNr = "#" + palette.semantic.text2;
          IncSearch = "#" + palette.semantic.background;
          Function = "#" + palette.semantic.text;
          BlinkCmpGhostText = "#" + palette.semantic.text1;
        };
        hlGroupsBg = {
          Visual = "#" + palette.semantic.text2;
          IncSearch = "#" + palette.accents.peach;
        };
      };
    });

  Ayu-Mirage = import ./ayu (themeArgs
    // {
      variant = "mirage";
      wallpaper = ./ayu/wallpapers/ayu-mirage-default.png;

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
    });

  Blue-Nightmare = import ./blue-nightmare themeArgs;

  Bluloco-Dark = import ./bluloco themeArgs;

  Catppuccin-Latte = import ./catppuccin (themeArgs
    // {
      variant = "latte";
      accent = "rosewater";
      accent2 = "blue";
      accent3 = "mauve";

      hyprlandOverrides = palette: {
        active1 = palette.accents.rosewater;
        active2 = palette.accents.mauve;
        inactive1 = palette.accents.lavender;
        inactive2 = palette.accents.teal;
      };

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
    });

  Catppuccin-Mocha = import ./catppuccin (themeArgs
    // {
      variant = "mocha";

      hyprlandOverrides = palette: {
        active1 = palette.accents.mauve;
        active2 = palette.accents.rosewater;
        inactive1 = palette.accents.lavender;
        inactive2 = "6c7086";
      };

      rofiOverrides = palette: {
        main-background = palette.all.crust;
        text = "cdd6f4";
        border = palette.accents.mauve;
        highlight = palette.accents.lavender;
        highlight-text = palette.all.crust;
      };

      waybarOverrides = palette: {
        overlay = palette.all.base;
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
    });

  Gruvbox-Dark = import ./gruvbox themeArgs;

  Newpaper-Light = import ./newpaper themeArgs;

  Oh-Lucy = import ./oh-lucy (themeArgs
    // {
      neovimOverrides = palette: {
        colorscheme = "oh-lucy";
      };
    });

  Oh-Lucy-Evening = import ./oh-lucy (themeArgs
    // {
      variant = "evening";
      neovimOverrides = palette: {
        colorscheme = "oh-lucy-evening";
      };
    });

  Rose-Pine = import ./rose-pine (themeArgs
    // {
      variant = "pine";
      neovimOverrides = palette: {
        colorscheme = "rose-pine-main";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
        };
        hlGroupsBg = {
          CursorLine = "#44415a";
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
      };
    });

  Rose-Pine-Eclipse = import ./rose-pine (themeArgs
    // {
      variant = "eclipse";
      neovimOverrides = palette: {
        colorscheme = "rose-pine-moon";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
        };
        hlGroupsBg = {
          CursorLine = "#44415a";
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
      };

      wallpaper = ./rose-pine/wallpapers/eclipse.png;
      kittyOverrides.file."theme.conf".source = ./rose-pine/eclipse-kitty.conf;
    });

  Rose-Pine-Moon = import ./rose-pine (themeArgs
    // {
      variant = "moon";
      neovimOverrides = palette: {
        colorscheme = "rose-pine-moon";
        background = "dark";
        hlGroupsFg = {
          HLChunk1 = "#c4a7e7";
          HLLineNum1 = "#c4a7e7";
        };
        hlGroupsBg = {
          CursorLine = "#44415a";
          Cursor = "#6e6a86";
          Folded = "#44415a";
        };
      };
      wallpaper = ./rose-pine/wallpapers/moon.png;
    });

  Tsoding-Mode = import ./tsoding-mode themeArgs;
}
